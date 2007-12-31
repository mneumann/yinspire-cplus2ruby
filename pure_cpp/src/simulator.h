#ifndef __YINSPIRE__SIMULATOR__
#define __YINSPIRE__SIMULATOR__

#include "types.h"
#include "neural_entity.h" 
#include "memory_allocator.h"
#include "algo/indexed_binary_heap.h"
#include <string.h>
#include <map>

struct ltstr
{
  inline bool operator()(const char *s1, const char *s2) const
  {
    return strcmp(s1, s2) < 0;
  }
};

class Simulator
{
    friend class NeuralEntity;

  protected:

    /*
     * The current time.
     */
    simtime schedule_current_time;

    /*
     * The time step used for stepped scheduling.
     */
    simtime schedule_step;

    /*
     * The time of the next step.
     */
    simtime schedule_next_step;

    /*
     * The tolerance (time difference) up to which local stimuli are
     * accumulated.
     */
    simtime stimuli_tolerance;

    /*
     * Priority queue used to schedule the entities.
     */
    IndexedBinaryHeap<NeuralEntity *, MemoryAllocator<NeuralEntity*>, NeuralEntity> schedule_pq;

    /*
     * If stepped scheduling is used, this points to the 
     * first entity in the stepped schedule list.   
     */
    NeuralEntity *schedule_stepping_list_root;

    /*
     * An id -> NeuralEntity mapping
     *
     * Contains all entities known by the simulator.
     */
    std::map<const char *, NeuralEntity *, ltstr> entities;

    /*
     * An entity type name -> "factory function for this type" mapping.
     */
    typedef NeuralEntity* (*entity_factory_t)();
    std::map<const char *, entity_factory_t, ltstr> types;

  public:

    /*
     * Constructor
     */
    Simulator();

    /*
     * Load the neural net from +filename+.
     */
    void load(const char *filename);

    /*
     * Start the simulation.
     */
    void run(simtime stop_at);

    /*
     * Register an entity type and the corresponding +factory+ function.
     */
    void entity_register_type(const char *type, entity_factory_t factory);

    /*
     * Allocate an entity of the specified +type+.
     */
    NeuralEntity *entity_allocate(const char *type);

    /*
     * If an entity has changed it's scheduling time,
     * it has to call this method to reflect the change within the
     * priority queue.
     */
    void schedule_update(NeuralEntity *entity);

    /*
     * Notify that a fire event has happened
     */
    void stat_record_fire_event(simtime at, NeuralEntity *source);

  public:

    uint stat_fire_counter;
    uint stat_event_counter;

};

#endif
