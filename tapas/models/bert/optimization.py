# coding=utf-8
# Copyright 2019 The Google AI Language Team Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Lint as: python3
"""Functions and classes related to optimization (weight updates)."""

import re
from typing import Optional
import tensorflow.compat.v1 as tf


def create_optimizer(loss,
                     init_lr,
                     num_train_steps,
                     num_warmup_steps,
                     use_tpu,
                     optimizer="adamw",
                     poly_power=1.0,
                     start_warmup_step=0,
                     gradient_accumulation_steps=1,
                     grad_clipping=None):
  """Creates an optimizer training op."""
  global_step = tf.train.get_or_create_global_step()

  learning_rate = tf.constant(value=init_lr, shape=[], dtype=tf.float32)

  # Implements linear decay of the learning rate.
  learning_rate = tf.train.polynomial_decay(
      learning_rate,
      global_step,
      num_train_steps,
      end_learning_rate=0.0,
      power=poly_power,
      cycle=False)

  # Implements linear warmup. I.e., if global_step - start_warmup_step <
  # num_warmup_steps, the learning rate will be
  # `(global_step - start_warmup_step)/num_warmup_steps * init_lr`.
  if num_warmup_steps:
    tf.logging.info("++++++ warmup starts at step " + str(start_warmup_step)
                    + ", for " + str(num_warmup_steps) + " steps ++++++")
    global_steps_int = tf.cast(global_step, tf.int32)
    start_warm_int = tf.constant(start_warmup_step, dtype=tf.int32)
    global_steps_int = global_steps_int - start_warm_int
    warmup_steps_int = tf.constant(num_warmup_steps, dtype=tf.int32)

    global_steps_float = tf.cast(global_steps_int, tf.float32)
    warmup_steps_float = tf.cast(warmup_steps_int, tf.float32)

    warmup_percent_done = global_steps_float / warmup_steps_float
    warmup_learning_rate = init_lr * warmup_percent_done

    is_warmup = tf.cast(global_steps_int < warmup_steps_int, tf.float32)
    learning_rate = (
        (1.0 - is_warmup) * learning_rate + is_warmup * warmup_learning_rate)

  # It is OK that you use this optimizer for finetuning, since this
  # is how the model was trained (note that the Adam m/v variables are NOT
  # loaded from init_checkpoint.)
  # It is OK to use AdamW in the finetuning even the model is trained by LAMB.
  # As report in the Bert pulic github, the learning rate for SQuAD 1.1 finetune
  # is 3e-5, 4e-5 or 5e-5. For LAMB, the users can use 3e-4, 4e-4,or 5e-4 for a
  # batch size of 64 in the finetune.
  if optimizer == "adamw":
    tf.logging.info("using adamw")
    optimizer = AdamWeightDecayOptimizer(
        learning_rate=learning_rate,
        weight_decay_rate=0.01,
        beta_1=0.9,
        beta_2=0.999,
        epsilon=1e-6,
        exclude_from_weight_decay=["LayerNorm", "layer_norm", "bias"],
        grad_clipping=grad_clipping)
  else:
    raise ValueError("Not supported optimizer: ", optimizer)

  # This is empirically better than adding the optimizer after the `use_tpu` if.
  if gradient_accumulation_steps > 1:
    optimizer = GradientAccumulationOptimizer(
        optimizer,
        steps=gradient_accumulation_steps,
        grad_clipping=grad_clipping)

  if use_tpu:
    optimizer = tf.tpu.CrossShardOptimizer(optimizer)

  tvars = tf.trainable_variables()
  grads = tf.gradients(loss, tvars)

  # This is how the model was pre-trained.
  (grads, _) = tf.clip_by_global_norm(grads, clip_norm=1.0)

  train_op = optimizer.apply_gradients(
      zip(grads, tvars), global_step=global_step)

  return train_op


class GradientAccumulationOptimizer(tf.train.Optimizer):
  """Optimizer wrapper providing gradient accumulation."""

  def __init__(self,
               opt,
               steps,
               grad_clipping = None):
    if steps <= 0:
      raise ValueError("GradientAccumulation expects steps to be positive.")
    self._opt = opt
    self._steps = steps
    self._grad_clipping = grad_clipping

  def _get_variable_name(self, param_name):
    """Get the variable name from the tensor name."""
    m = re.match("^(.*):\\d+$", param_name)
    if m is not None:
      param_name = m.group(1)
    return param_name

  def apply_gradients(self, grads_and_vars, global_step=None, name=None):
    counter = tf.get_variable(
        shape=[], initializer=tf.zeros_initializer, name="counter")
    accums = []
    variables = []
    for (grad, param) in grads_and_vars:
      if grad is None or param is None:
        continue

      if self._grad_clipping is not None:
        grad_clipping = self._steps * self._grad_clipping
        grad = tf.clip_by_value(grad, -grad_clipping, grad_clipping)

      variables.append(param)
      param_name = self._get_variable_name(param.name)

      accum = tf.get_variable(
          name=param_name + "/accum",
          shape=param.shape.as_list(),
          dtype=tf.float32,
          trainable=False,
          initializer=tf.zeros_initializer())
      if isinstance(grad, tf.IndexedSlices):
        scaled_grad = tf.IndexedSlices(
            grad.values / self._steps,
            grad.indices,
            dense_shape=grad.dense_shape)
        accums.append(accum.assign_add(scaled_grad))
      else:
        accums.append(accum.assign_add(grad / self._steps))

    def _apply_and_zero():
      apply_op = self._opt.apply_gradients(
          list(zip(accums, variables)), global_step, name)
      with tf.control_dependencies([apply_op]):
        zero_op = [
            tf.assign(accum, tf.zeros_like(accum))
            for accum in accums + [counter]
        ]
      return tf.group(zero_op)

    def _accum():
      return tf.group(accums)

    # Control that the counter has been incremented already
    with tf.control_dependencies([counter.assign_add(1)]):
      return tf.cond(
          tf.equal(tf.mod(counter, self._steps), 0), _apply_and_zero, _accum)


class AdamWeightDecayOptimizer(tf.train.Optimizer):
  """A basic Adam optimizer that includes "correct" L2 weight decay."""

  def __init__(self,
               learning_rate,
               weight_decay_rate=0.0,
               beta_1=0.9,
               beta_2=0.999,
               epsilon=1e-6,
               exclude_from_weight_decay=None,
               grad_clipping=None,
               name="AdamWeightDecayOptimizer"):
    """Constructs a AdamWeightDecayOptimizer."""
    super(AdamWeightDecayOptimizer, self).__init__(False, name)

    self.learning_rate = learning_rate
    self.weight_decay_rate = weight_decay_rate
    self.beta_1 = beta_1
    self.beta_2 = beta_2
    self.epsilon = epsilon
    self.exclude_from_weight_decay = exclude_from_weight_decay
    self.grad_clipping = grad_clipping

  def apply_gradients(self, grads_and_vars, global_step=None, name=None):
    """See base class."""
    assignments = []
    for (grad, param) in grads_and_vars:
      if grad is None or param is None:
        continue
      if self.grad_clipping is not None:
        grad = tf.clip_by_value(grad, -1 * self.grad_clipping,
                                self.grad_clipping)

      param_name = self._get_variable_name(param.name)

      m = tf.get_variable(
          name=param_name + "/adam_m",
          shape=param.shape.as_list(),
          dtype=tf.float32,
          trainable=False,
          initializer=tf.zeros_initializer())
      v = tf.get_variable(
          name=param_name + "/adam_v",
          shape=param.shape.as_list(),
          dtype=tf.float32,
          trainable=False,
          initializer=tf.zeros_initializer())

      # Standard Adam update.
      next_m = (
          tf.multiply(self.beta_1, m) + tf.multiply(1.0 - self.beta_1, grad))
      next_v = (
          tf.multiply(self.beta_2, v) + tf.multiply(1.0 - self.beta_2,
                                                    tf.square(grad)))

      update = next_m / (tf.sqrt(next_v) + self.epsilon)

      # Just adding the square of the weights to the loss function is *not*
      # the correct way of using L2 regularization/weight decay with Adam,
      # since that will interact with the m and v parameters in strange ways.
      #
      # Instead we want ot decay the weights in a manner that doesn't interact
      # with the m/v parameters. This is equivalent to adding the square
      # of the weights to the loss with plain (non-momentum) SGD.
      if self._do_use_weight_decay(param_name):
        update += self.weight_decay_rate * param

      update_with_lr = self.learning_rate * update

      next_param = param - update_with_lr

      assignments.extend(
          [param.assign(next_param),
           m.assign(next_m),
           v.assign(next_v)])
    return tf.group(
        global_step.assign(global_step + 1), *assignments, name=name)

  def _do_use_weight_decay(self, param_name):
    """Whether to use L2 weight decay for `param_name`."""
    if not self.weight_decay_rate:
      return False
    if self.exclude_from_weight_decay:
      for r in self.exclude_from_weight_decay:
        if re.search(r, param_name) is not None:
          return False
    return True

  def _get_variable_name(self, param_name):
    """Get the variable name from the tensor name."""
    m = re.match("^(.*):\\d+$", param_name)
    if m is not None:
      param_name = m.group(1)
    return param_name
