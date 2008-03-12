#include "neural_entity.h"
#include "simulator.h"
#include <math.h>

NeuralEntity::NeuralEntity()
{
  this->simulator = NULL;
  this->id = NULL;
  this->schedule_index = 0;
  this->schedule_at = INFINITY;
  this->schedule_stepping_list_prev = NULL;
  this->schedule_stepping_list_next = NULL;
  this->schedule_stepping_list_internal_next = NULL;
}

NeuralEntity::~NeuralEntity()
{
}


void
NeuralEntity::load(jsonHash *data)
{
}

void
NeuralEntity::dump(jsonHash *into)
{
}

static void
iter_disconnect(NeuralEntity *self, NeuralEntity *conn)
{
  self->disconnect(conn);
}

void
NeuralEntity::disconnect_all()
{
  each_connection(iter_disconnect);
}

void
NeuralEntity::schedule(simtime at)
{
  // FIXME: make sure that this->schedule_at is reset
  // when the entity is removed from the pq.
  if (this->schedule_at != at)
  {
    this->schedule_at = at;
    this->simulator->schedule_update(this);
  }
}

inline bool
NeuralEntity::schedule_stepping_enabled()
{
  return (this->schedule_stepping_list_prev != NULL && 
          this->schedule_stepping_list_next != NULL);
}

void
NeuralEntity::schedule_enable_stepping()
{
  if (!schedule_stepping_enabled())
  {
    NeuralEntity*& root = this->simulator->schedule_stepping_list_root; 
    if (root != NULL)
    {
      this->schedule_stepping_list_prev = root;
      this->schedule_stepping_list_next = root->schedule_stepping_list_next;
      root->schedule_stepping_list_next = this; 
      this->schedule_stepping_list_next->schedule_stepping_list_prev = this; 
    }
    else
    {
      root = this; 
      this->schedule_stepping_list_prev = this;
      this->schedule_stepping_list_next = this;
    }
  }
}

void
NeuralEntity::schedule_disable_stepping()
{
  if (schedule_stepping_enabled())
  {
    if (this->schedule_stepping_list_prev != this->schedule_stepping_list_next)
    {
      this->schedule_stepping_list_prev->schedule_stepping_list_next = this->schedule_stepping_list_next; 
      this->schedule_stepping_list_next->schedule_stepping_list_prev = this->schedule_stepping_list_prev;  
    }
    else
    {
      /*
       * We are the last entity in the stepping list.
       */
      this->simulator->schedule_stepping_list_root = NULL;
      this->schedule_stepping_list_prev = NULL;
      this->schedule_stepping_list_next = NULL;
    }
  }
}

static bool
stimuli_accum(Stimulus &parent, const Stimulus &element, void *tolerance)
{
  if ((element.at - parent.at) > *((real*)tolerance)) return false;

  if (isinf(element.weight))
  {
    /*
     * We only accumulate two infinitive values!
     */
    return (isinf(parent.weight) ? true : false);
  }

  parent.weight += element.weight;
  return true;
}

void
NeuralEntity::stimuli_add(simtime at, real weight)
{
  Stimulus s; s.at = at; s.weight = weight;
  if (this->simulator->stimuli_tolerance >= 0.0)
  {
    //find_parent
    if (this->stimuli_pq.accumulate(s, stimuli_accum, &this->simulator->stimuli_tolerance)) return;
  }
  this->stimuli_pq.push(s);
  schedule(this->stimuli_pq.top().at);
}

real
NeuralEntity::stimuli_sum(simtime until)
{
  real weight = 0.0;

  while (!this->stimuli_pq.empty() && this->stimuli_pq.top().at <= until)
  {
    weight += this->stimuli_pq.top().weight;
    this->stimuli_pq.pop();
  }

  /*
   * NOTE: we don't have to remove the entity from the schedule if the
   * pq is empty.
   */
  if (!this->stimuli_pq.empty())
  {
    schedule(this->stimuli_pq.top().at);
  }

  return weight;
}

real
NeuralEntity::stimuli_sum_inf(simtime until, bool &is_inf)
{
  real weight = 0.0;
  is_inf = false;

  while (!this->stimuli_pq.empty() && this->stimuli_pq.top().at <= until)
  {
    if (isinf(this->stimuli_pq.top().weight))
    {
      is_inf = true;
    }
    else
    {
      weight += this->stimuli_pq.top().weight;
    }
    this->stimuli_pq.pop();
  }

  if (!this->stimuli_pq.empty())
  {
    schedule(this->stimuli_pq.top().at);
  }

  return weight;
}

void
NeuralEntity::set_simulator(Simulator *simulator)
{
  this->simulator = simulator;
}

Simulator *
NeuralEntity::get_simulator() const
{
  return this->simulator; 
}

void
NeuralEntity::set_id(const char *id)
{
  this->id = id;
}

const char *
NeuralEntity::get_id() const
{
  return this->id;
}
