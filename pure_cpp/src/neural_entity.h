#ifndef __YINSPIRE__NEURAL_ENTITY__
#define __YINSPIRE__NEURAL_ENTITY__

#include "types.h"
#include "memory_allocator.h"
#include "algo/binary_heap.h"
#include "json/json.h"

class Simulator; // forward declaration

/*
 * The data structure used for storing a fire impluse or any other form
 * of stimulation.
 */
struct Stimulus
{
  simtime at;
  real weight;

  inline static bool
    bh_cmp_gt(Stimulus &a, Stimulus &b)
    {
      return (a.at > b.at); 
    }
};

/*
 * The NeuralEntity is the base class of all entities in a neural net,
 * i.e. Neurons and Synapses. 
 */
class NeuralEntity
{
  protected: 

    /*
     * Each NeuralEntity has a pointer to the Simulator.
     * This is used for example to update it's scheduling
     * or to report a fire event.
     *
     * It's assigned by the Simulator!
     */
    Simulator *simulator;

    /*
     * Each NeuralEntity has an +id+ associated which uniquely
     * identifies itself within a Simulator instance. This +id+ is
     * assigned by the Simulator and should not be changed by the
     * NeuralEntity itself.
     *
     * The reference is NOT owned by the NeuralEntity. It's the
     * responsibility of the Simulator to allocate and free the memory! 
     */
    const char *id;

    /*
     * Index of this entity in the entity priority queue managed by the
     * Simulator. If schedule_index is zero then the entity is currently
     * not present in the priority queue and as such the entity is not
     * scheduled for a specific time.
     */
    uint schedule_index;

    /*
     * The timestamp of the earliest event in the local priority queue.
     */
    simtime schedule_at;

    /*
     * If stepped scheduling is used, points to the previous/next
     * entity in the schedule list.
     */
    NeuralEntity *schedule_stepping_list_prev;
    NeuralEntity *schedule_stepping_list_next;

    /*
     * To be able to modify the stepped scheduling list
     * (schedule_stepping_list_prev/next) during stepped schedule
     * processing, we build up an internal linked list that we use to
     * traverse all entities that require stepped schedule processing. 
     * 
     * This is cheaper than using an externalized linked list, as we
     * would have to allocate memory, which we overcome with this
     * approach.
     *
     * This is only used by the simulator!
     */
    NeuralEntity *schedule_stepping_list_internal_next;

    /*
     * Each NeuralEntity has it's own local stimuli priority queue.
     * Neurons make use of this whereas Synapses currently not. 
     *
     * It's a quite low overhead to have this in the NeuralEntity class,
     * just around 12 additional bytes.
     */
    BinaryHeap<Stimulus, MemoryAllocator<Stimulus> > stimuli_pq;

  public:

    /*
     * Constructor
     */
    NeuralEntity();

    /*
     * Destructor
     */
    virtual ~NeuralEntity();

    /*
     * Load the internal state of a NeuralEntity
     * from +data+.
     *
     * Note that loading does not neccessarily reset
     * the internal state of the entity!
     */
    virtual void load(jsonHash *data); 

    /*
     * Dump the internal state of a NeuralEntity
     * and return it. Internal state does not contain 
     * the network connection (they have to be dumped
     * separatly by the simulator using +each_connection+.
     */ 
    virtual void dump(jsonHash *into);

    /*
     * Connect +self+ with +target+.
     */
    virtual void connect(NeuralEntity *target) = 0;

    /*
     * Disconnect +self+ from +target+.
     */
    virtual void disconnect(NeuralEntity *target) = 0;

    /*
     * Disconnect from all connections. Uses +each_connection+ and
     * +disconnect+.
     */
    void disconnect_all();

    /*
     * Calls the iterator function for each outgoing connection.
     */
    virtual void each_connection(
        void (*yield)(NeuralEntity *self, NeuralEntity *conn)) = 0;

    /*
     * Stimulate an entity at a specific time with a specific weight.
     */
    virtual void stimulate(simtime at, real weight, NeuralEntity *source) = 0;

    /*
     * This method is called when a NeuralEntity reached it's scheduling
     * time.
     *
     * Overwrite it if you need this behaviour.
     */
    virtual void
      process(simtime at)
      {
        throw "Abstract method";
      } 

    /*
     * This method is called in each time-step, if a NeuralEntity
     * uses stepped scheduling. 
     *
     * Overwrite it if you need this behaviour.
     */
    virtual void
      process_stepped(simtime at, simtime step)
      { 
        throw "Abstract method";
      }

    /*
     * Attribute accessor functions
     */
    void        set_simulator(Simulator *simulator);
    void        set_id(const char *id);
    Simulator  *get_simulator() const;
    const char *get_id() const;
    inline simtime get_schedule_at() const { return @schedule_at; }

  protected:

    /*
     * Schedules the entity at a specific time.
     */
    void schedule(simtime at);

    /*
     * Returns true if stepped scheduling is enabled.
     */
    bool schedule_stepping_enabled();

    /* 
     * Enable/Disable stepped scheduling. 
     */
    void schedule_enable_stepping();
    void schedule_disable_stepping();

    /*
     * Add a Stimuli to the local pq.
     */
    void stimuli_add(simtime at, real weight);

    /*
     * Sum all Stimuli until +until+.
     */
    real stimuli_sum(simtime until);

    /*
     * Sum all Stimuli until +until+, but treat infinite values
     * differently.  Do not sum them, instead set +is_inf+ to true.
     */
    real stimuli_sum_inf(simtime until, bool &is_inf);

  public:

    /*
     * Accessor function for BinaryHeap
     */
    inline static bool
      bh_cmp_gt(NeuralEntity *a, NeuralEntity *b)
      {
        return (a->schedule_at > b->schedule_at);
      }

    /*
     * Accessor function for BinaryHeap
     */
    inline static uint &
      bh_index(NeuralEntity *self)
      {
        return self->schedule_index;
      }

};

#endif
