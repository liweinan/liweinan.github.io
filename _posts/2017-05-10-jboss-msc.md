---
title: "An introduction to the JBoss Modular Service Container: Part 1 - Basic architecture of the container"
author: Weinan
---

The `JBoss Modular Service Container` project is the core part of the Wildfly application server, and it provides the Wildfly server the ability to install or remove components (called services) at runtime. In this series of articles, I'd like to make an introduction to the project.

This project is hosted on Github (most of the JBoss projects are hosted on Github), and the project name is `jboss-msc2` ([https://github.com/jboss-msc/jboss-msc2](https://github.com/jboss-msc/jboss-msc2)). There is also a `jboss-msc` project, but the `jboss-msc2` is for the future, so I will focus on the newer one in this series of articles.

I won't introduce the method to clone the project into you local machine in this article. You can read [Fetching and compiling the Wildfly upstream source](http://wildflyinternals.io/2017/05/05/wildfly-src.html) to get a basic idea on how to fetch and build the opensource projects from Github.

Basically, the service container can be divided into two parts. One part is the transaction layer, which is used to control the lifecycle of the service. The other part is the service layer, which defines the concepts like service container and service registries (Please note the project does not divide itself into two sub-modules or two layers explicitly, and we can just roughly divide it like this in our mind to help us to better understanding the whole project). We will check these concepts in more details in this series of articles.

Now let's see the class diagram that contains classes related with the service layer:

![/assets/msc/services.png](/assets/msc/services.png)

The above diagram contains some classes that compose the design of the service container. There are fives interfaces we need to check in detail. They are `ServiceController`, `ServiceBuilder`, `ServiceRegistry`, `ServiceContainer` and `Service`. Let check them one by one.

The first interface to check is `ServiceContainer`. This is the container class, and it is created from the `newServiceContainer(...)` method of `TransactionController` class. We won't touch much about the transaction layer here, but you need to know the concept of transaction in `jboss-msc2` is not the same thing in database or transaction processing area. The concept of transaction in service container is more like a lifecycle controller and task executor of the services. We will check the details of transaction later.

Here is the diagram that shows our above analyzed result:

![/assets/msc/container.png](/assets/msc/container.png)

Now let's come back to the `ServiceContainer` interface. Here is the code of the interface:

```java
package org.jboss.msc.service;

import org.jboss.msc.txn.InvalidTransactionStateException;
import org.jboss.msc.txn.UpdateTransaction;
import org.jboss.msc.util.Listener;

/**
 * A service container. Implementations of this interface are thread safe.
 *
 * @author <a href="mailto:david.lloyd@redhat.com">David M. Lloyd</a>
 * @author <a href="mailto:frainone@redhat.com">Flavia Rainone</a>
 * @author <a href="mailto:ropalka@redhat.com">Richard Opalka</a>
 */
public interface ServiceContainer {

    /**
     * Creates new registry associated with this container.
     *
     * @param transaction the transaction
     * @return container registry
     * @throws IllegalStateException if container have been shutdown
     */
    ServiceRegistry newRegistry(UpdateTransaction transaction);

    /**
     * Shuts down the container, removing all registries and their services.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service container.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this container
     */
    void shutdown(UpdateTransaction transaction) throws IllegalArgumentException, InvalidTransactionStateException;

    /**
     * Shuts down the container, removing all registries and their services.
     *
     * @param transaction the transaction
     * @param completionListener called when operation is finished
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service container.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this container
     */
    void shutdown(UpdateTransaction transaction, Listener<ServiceContainer> completionListener) throws IllegalArgumentException, InvalidTransactionStateException;

}
```

The above code contains the methods that the container provides and it has document to describe the purpose of these methods. We can see a container can contain multiple service registries represented by `ServiceRegistry` interface. The container can also be shutdown with `shutdown(...)` methods, and all the services in the container will be closed and their registries will be removed. There are transactions and listeners associated with these actions (`UpdateTransaction` class and `Listener` interface are passed into the methods).

The container relies on the associated transaction to manage its   state transitions, and these transitions are asynchronous actions, so it needs a callback listener after the action is done. We will check the detail of this part of the design later in this series of articles.

Now let's check the `ServiceRegistry` interface. Here is the code of the interface:

```java
package org.jboss.msc.service;

import org.jboss.msc.txn.InvalidTransactionStateException;
import org.jboss.msc.txn.UpdateTransaction;
import org.jboss.msc.util.Listener;

/**
 * A service registry. Implementations of this interface are thread safe.
 *
 * @author <a href="mailto:david.lloyd@redhat.com">David M. Lloyd</a>
 * @author <a href="mailto:frainone@redhat.com">Flavia Rainone</a>
 * @author <a href="mailto:ropalka@redhat.com">Richard Opalka</a>
 */
public interface ServiceRegistry {

    /**
     * Gets a service controller, throwing an exception if it is not found.
     *
     * @param serviceName the service name
     * @param <T> service controller value type
     * @return the service controller corresponding to {@code serviceName}
     * @throws ServiceNotFoundException if the service is not present in the registry
     */
    <T> ServiceController<T> getRequiredService(ServiceName serviceName) throws ServiceNotFoundException;

    /**
     * Gets a service controller, returning {@code null} if it is not found.
     *
     * @param serviceName the service name
     * @param <T> service controller value type
     * @return the service controller corresponding to {@code serviceName}, or {@code null} if it is not found
     */
    <T> ServiceController<T> getService(ServiceName serviceName);

    /**
     * Disables this registry and all its services, causing {@code UP} services to stop.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service registry.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this registry
     */
    void disable(UpdateTransaction transaction) throws IllegalArgumentException, InvalidTransactionStateException;

    /**
     * Enables this registry. As a result, its services may start, depending on their
     * {@link org.jboss.msc.service.ServiceMode mode} rules.
     * <p> Registries are enabled by default.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service registry.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this registry
     */
    void enable(UpdateTransaction transaction) throws IllegalArgumentException, InvalidTransactionStateException;

    /**
     * Removes this registry from the container.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service registry.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this registry
     */
    void remove(UpdateTransaction transaction) throws IllegalArgumentException, InvalidTransactionStateException;

    /**
     * Removes this registry from the container.
     *
     * @param transaction the transaction
     * @param completionListener called when operation is finished
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service registry.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     * @throws IllegalArgumentException if transaction was created by different transaction controller than this registry
     */
    void remove(UpdateTransaction transaction, Listener<ServiceRegistry> completionListener) throws IllegalArgumentException, InvalidTransactionStateException;

}
```

From the above code, we can see the `ServiceRegistry` includes many services, and it have `getService(...)` method to fetch the include services. In addition, it has `remove(...)` and `enable(...)` methods to manage its lifecycle in container.'

We need to take caution that the `getService(...)` method will get an instance of `ServiceController` as its returned data, instead of the services itself. The `ServiceController` interface defines a model to control the lifecycle of its service. The real service is represented by `Service` interface, and there is a `Registration` class stores a `ServiceRegistry` with its `ServiceName`. The following diagram shows the relationship of these classes:
 
![/assets/msc/servicecontroller.png](/assets/msc/servicecontroller.png)

The above diagram shows that the `ServiceController` is the interface that manages the lifecycle of the underlying service. Here is part of the code in `ServiceController` interface:
 
```java
package org.jboss.msc.service;

import org.jboss.msc.txn.InvalidTransactionStateException;
import org.jboss.msc.txn.UpdateTransaction;
import org.jboss.msc.util.Listener;


/**
 * A controller for a single service instance.
 *
 * @author <a href="mailto:frainone@redhat.com">Flavia Rainone</a>
 * @author <a href="mailto:ropalka@redhat.com">Richard Opalka</a>
 * @param <T> service type
 */
public interface ServiceController<T> {

    /**
     * Disables a service, causing this service to stop if it is {@code UP}.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service controller.
     * @throws IllegalStateException if controller was removed
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void disable(UpdateTransaction transaction) throws IllegalArgumentException, IllegalStateException, InvalidTransactionStateException;

    /**
     * Enables the service, which may start as a result, according to its {@link org.jboss.msc.service.ServiceMode mode} rules.
     * <p> Services are enabled by default.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service controller.
     * @throws IllegalStateException if controller was removed
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void enable(UpdateTransaction transaction) throws IllegalArgumentException, IllegalStateException, InvalidTransactionStateException;

    /**
     * Removes this service.<p>
     * All dependent services will be automatically stopped as the result of this operation.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service controller.
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void remove(UpdateTransaction transaction) throws IllegalArgumentException, InvalidTransactionStateException;
    /**
     * Restarts this service.
     * 
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service controller.
     * @throws IllegalStateException if controller was removed
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void restart(UpdateTransaction transaction) throws IllegalArgumentException, IllegalStateException, InvalidTransactionStateException;

    /**
     * Retries a failed service. Does nothing if the state has not failed.
     *
     * @param transaction the transaction
     * @throws java.lang.IllegalArgumentException if <code>transaction</code> is null
     * or if transaction controller associated with <code>transaction</code>
     * is not the same as the one associated with this service controller.
     * @throws IllegalStateException if controller was removed
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void retry(UpdateTransaction transaction) throws IllegalArgumentException, IllegalStateException, InvalidTransactionStateException;

    /**
     * Replaces {@code service} by a new service.
     *
     * @param transaction the transaction
     * @param newService the new service to be published
     * @throws java.lang.IllegalArgumentException if any method parameter is <code>null</code>
     * @throws IllegalStateException if controller was removed
     * @throws org.jboss.msc.txn.InvalidTransactionStateException if transaction is not active.
     */
    void replace(UpdateTransaction transaction, Service<T> newService) throws IllegalArgumentException, IllegalStateException, InvalidTransactionStateException;

    /**
     * Gets associated service.
     * @return service
     */
    Service<T> getService();

}
```

From the above code, we can see that the `ServiceController` interface is the physical layer to control the `Service` lifecycle in container. The `Service` interface should be implemented by each service vendor. Here is the code of the `Service` interface:

```java
package org.jboss.msc.service;

/**
 * Service interface providing both start and stop methods to implementors.
 * <p>
 * Service implementors will have start invoked both on execution phase (when the service is being started) and during
 * rollback (when a stop is being reverted). The same is valid for stop: it could be invoked during both execution
 * and rollback stages of active transaction.
 * 
 * @param <T> the service value type
 * 
 * @author <a href="mailto:frainone@redhat.com">Flavia Rainone</a>
 */
public interface Service<T> {

    /**
     * Service start  method, invoked on execution and rollback (when needed to revert a previous stop).
     * <p>
     * Implementors must invoke {@link StartContext#complete(Object) startContext.complete(T)} upon completion.
     * <p>
     * Also, this method cannot be implemented asynchronously.
     * 
     * @param startContext the start context
     */
    void start(StartContext<T> startContext);

    /**
     * Service stop method, invoked on execution and rollback (when needed to revert a previous start).
     * <p>
     * Implementors must invoke {@link StopContext#complete() stopContext.complete()} upon completion.
     * <p>
     * Also, this method cannot be implemented asynchronously.
     * 
     * @param stopContext the stop context
     */
    void stop(StopContext stopContext);

}
```

From the above code, we can see the `Service` interface defines `start(...)` and `stop(...)` methods for the users to implement. Wildfly contains many subsystems, and these systems will need to implement the `Service` interface to run in container. We can see the `org.jboss.as.connector.subsystems.datasources.XADataSourceConfigService` class ([XADataSourceConfigService.java](https://github.com/wildfly/wildfly/blob/master/connector/src/main/java/org/jboss/as/connector/subsystems/datasources/XADataSourceConfigService.java)) in Wildfly as an implementation example.

Seeing from the above diagram and code, we can understand the relationship between `ServiceContainer`, `ServiceRegistry`, `Registration`, `ServiceController` and `Service`. Firstly, `ServiceContainer` contains many `ServiceRegistry` instances. Here is the relative code in `ServiceContainerImpl` class:
 
```java
private final Set<ServiceRegistryImpl> registries = new HashSet<>();
```

Secondly, the `ServiceRegistry` contains many `Registration` instances and belonging container. Here is the code in `ServiceRegistryImpl`:

```java
final ServiceContainerImpl container;

// map of service registrations
private final ConcurrentMap<ServiceName, Registration> registry = new ConcurrentHashMap<>();
```

From above code, we can see the registrations are stored in a concurrent map data structure, and the key is service name. Actually the `Registration` class contains the `ServiceName` by itself. The purpose that `ServiceRegistry` stores a `ServiceName` with `Registration` is for implementation requirement. We don't have to dig deeper here right now. 

Now let's see the `Registration` class. It contains `ServiceName`, `ServiceController` and belonging `ServiceRegistry`. Here is the relative code in `Registration` class:

```java
/** Registration name */
private final ServiceName serviceName;
/** Associated registry */
final ServiceRegistryImpl registry;
/** Associated controller */
final AtomicReference<ServiceControllerImpl<?>> holderRef = new AtomicReference<>();
```

From the above data, we can see `Registration` is like a bridge between `ServiceRegistry` and `ServiceController`.

Finally we come to `ServiceController`. It contains the instance of `Service` implementation and physically manage the service lifecycle with the help the transaction layer. We will check the transaction layer later, and that's all for our analyze in container layer.   

Finally, let's check the shutdown process of `ServiceContainer` to see how the call chains go through the above classes. Firstly let's see the sequence diagram of the `shutdown(...)` method in `ServiceContainerImpl`:

![/assets/msc/org.jboss.msc.txn.ServiceContainerImpl.shutdown(UpdateTransaction, Listener_ServiceContainer_).png](/assets/msc/org.jboss.msc.txn.ServiceContainerImpl.shutdown(UpdateTransaction, Listener_ServiceContainer_).png)

In above sequence diagram, we can see there is a loop to fetch the `ServiceRegistryImpl` instances from `registries`, and then the `remove(...)` method of `ServiceRegistryImpl` class instance will be called. Here is the relative code in `shutdown(...)` methjod:

```java
for (final ServiceRegistryImpl registry : registries) {
    registry.remove(txn);
}
```

From the above code, we can see how the call chain goes to `ServiceRegistryImpl.remove(...)` method. Now let's check the sequence diagram of the `ServiceRegistryImpl.remove(...)` method:

![/assets/msc/org.jboss.msc.txn.ServiceRegistryImpl.remove(UpdateTransaction, Listener_ServiceRegistry_).png](/assets/msc/org.jboss.msc.txn.ServiceRegistryImpl.remove(UpdateTransaction, Listener_ServiceRegistry_).png)

From the above diagram, we can see the main logic is to create a `RemoveTask` to remove the installed services. `RemoveTask` is an inner class of the `ServiceRegistryImpl` class. We can see the remove action is implemented asynchronously. `removeObservers` are used to observe the remove task execution, and `completionListener` is called after the execution is finished. Here is the relative code of the above process:

```java
synchronized (lock) {
    if (Bits.allAreClear(state, REMOVED)) {
        state = (byte) (state | REMOVED);
        if (installedServices > 0) {
            final RemoveTask removeTask = new RemoveTask(txn);
            getAbstractTransaction(txn).getTaskFactory().newTask(removeTask).release();
            if (completionListener != null) {
                removeObservers = new NotificationEntry(removeObservers, completionListener);
            }
            return; // don't call completion listener
        }
        container.registryRemoved();
    }
}
if (completionListener != null) safeCallListener(completionListener); // open call
```

The above code shows how the `RemoveTask` is created and called asynchronously. Now let's see the class diagram of `RemoveTask`:

![/assets/msc/RemoveTask.png](/assets/msc/RemoveTask.png)

Because `RemoveTask` is a inner class of the `ServiceRegistryImpl` class, so I keep the relationship in above diagram. Now let's check how does RemoveTask performs the remove action. Here is the code of the `RemoveTask`:

```java
private final class RemoveTask implements Executable<Void> {

    private final Transaction txn;

    public RemoveTask(final Transaction txn) {
        this.txn = txn;
    }

    @Override
    public void execute(final ExecuteContext<Void> context) {
        try {
            synchronized (ServiceRegistryImpl.this.lock) {
                for (final Registration registration : registry.values()) {
                    registration.remove(txn);
                }
                registry.clear();
            }
        } finally {
            context.complete();
        }
    }
}
```

From the above code, we can see `RemoveTask` implements the `org.jboss.msc.txn.Executable` interface. Here is the code of `org.jboss.msc.txn.Executable` interface:

```java
package org.jboss.msc.txn;

/**
 * A task that may succeed or fail which may also produce a consumable result.  If no result
 * is generated by this task, then its type should be {@code Void}.
 *
 * @param <T> the result type of this task
 * @author <a href="mailto:david.lloyd@redhat.com">David M. Lloyd</a>
 */
interface Executable<T> {

    /**
     * Perform the task.
     *
     * @param context execution context
     */
    void execute(ExecuteContext<T> context);
}
```

From the above code, we can see the `Executable` defines a `execute(...)` method for its represented task to be executed. Now we can go back to the `execute(...)` method implementation in `RemoveTask`. Here is the main logic in the code:

```java
for (final Registration registration : registry.values()) {
    registration.remove(txn);
}
registry.clear();
```

From the above code, we can see the registrations in registry will be traversed and their `remove(...)` method will be called. Finally the registry itself will be cleared by calling its `clear()` method.

Now we can go into the `Registration.remove(...)` method to see its logic. Here is the sequence diagram of the `Registration.remove(...)` method:

![/assets/msc/org.jboss.msc.txn.Registration.remove(Transaction).png](/assets/msc/org.jboss.msc.txn.Registration.remove(Transaction).png)

From the above diagram, we can see the `Registration.remove(...)` method will call the `_remove(...)` method of the included `ServiceController` instance.

The above study shows us how does the service container shutdown itself. It will shutdown the containing service registries, and service registry will remove its registrations and then clear registry itself. The registration will use service controller to shutdown the containing service.

We haven't checked the implementation of the `_remove(...)` method in `ServiceControllerImpl`, now let's see the code of the `_remove(...)` method in `ServiceControllerImpl`:
 
```java
void _remove(final Transaction txn, final Listener<ServiceController<T>> completionListener) throws IllegalArgumentException, InvalidTransactionStateException {
    synchronized (lock) {
        while (true) {
            if (isServiceRemoved()) break;
            state |= SERVICE_REMOVED;
            transition(txn);
            break;
        }
        if (completionListener == null) return;
        if (getState() != STATE_REMOVED) {
            this.removeObservers = new NotificationEntry<>(this.removeObservers, completionListener);
            return; // don't call completion listener
        }
    }
    safeCallListener(completionListener);
}
```

The main logic of above code is this part:

```java
while (true) {
    if (isServiceRemoved()) break;
    state |= SERVICE_REMOVED;
    transition(txn);
    break;
}
```

In above code, we can see the lifecycle of the service is controlled by `state`, and the state change is controlled by `transition(...)` method. Here is the sequence diagram of the `transition(...)` method:

![/assets/msc/org.jboss.msc.txn.ServiceControllerImpl.transition(Transaction).png](/assets/msc/org.jboss.msc.txn.ServiceControllerImpl.transition(Transaction).png)

From the above diagram, we can see the service has an implicit state machine defined inside the `transition(...)` method. And the state machine is powered by the transaction layer. We won't check much detail of this level in this article and we can stop our investigation at this level for now. Here is the code of the above diagram:

```java
private void transition(final Transaction txn) {
    assert holdsLock(lock);
    final boolean removed = isServiceRemoved();
    switch (getState()) {
        case STATE_DOWN:
            if (unsatisfiedDependencies == 0 && shouldStart()) {
                setState(STATE_STARTING);
                StartServiceTask.create(this, txn);
            } else if (removed) {
                setState(STATE_REMOVING);
                RemoveServiceTask.create(this, txn);
            }
            break;
        case STATE_UP:
            if (unsatisfiedDependencies > 0 || shouldStop()) {
                lifecycleTime = System.nanoTime();
                setState(STATE_STOPPING);
                StopServiceTask.create(this, txn);
            }
            break;
        case STATE_FAILED:
            if (unsatisfiedDependencies > 0 || shouldStop()) {
                lifecycleTime = System.nanoTime();
                setState(STATE_STOPPING);
                StopFailedServiceTask.create(this, txn);
            }
            break;
    }
}
```

From the above code, we can see `Transaction txn` is passed into multiple tasks related with the service lifecycle. These tasks will physically control the lifecycle of the `Service` instance in service controller. For example, here is part of the `execute(...)` method in `StopServiceTask`:

```java
public void execute(final ExecuteContext<Void> context) {
    final Service<T> service = serviceController.getService();
    if (service == null) {
        serviceController.setServiceDown(transaction);
        serviceController.notifyServiceDown(transaction);
        context.complete();
        return;
    }
...
```

From the above code, we can see the `StopServiceTask` will in return call the `setServiceDown(...)` method in its belonging service controller. The lower level of the state change needs to interact with the transaction layer, and we won't check into deeper call chain now.
 
 In this article, we have made a brief study on the service container design of the `jboss-msc2` project. This project is the core part of the Wildfly application server, and it provides the application server the ability to install and uninstall modules at runtime. In the next article, I'll introduce the transaction layer of the project.




