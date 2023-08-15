---
title: Java：「Executors」与「Thread Group」
abstract: 最近在做和「异步」相关的开发，有机会对「Executors」这一套设计做了更细致的学习，在这里记录一下。
---



最近在做和「异步」相关的开发，有机会对「Executors」这一套设计做了更细致的学习，在这里记录一下。

下面这段代码使用「ExecutorService」执行一个任务：

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ExecutorsDemo {

	public static void main(String[] args) {
		ExecutorService executorService = Executors.newSingleThreadExecutor();
		executorService.submit(() -> {
			try {
				Thread.currentThread().wait();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		});

		// main thread会在这里block住。
	}
}
```

如上所示，这个任务永远不会结束：

```java
Thread.currentThread().wait();
```

虽然我们使用的是「SingleThreadExecutor」，但它也会开启一个新的Thread执行任务。但是如果跑上面的代码，我们会发现main thread会被这个task给block住。下面是代码执行的截图：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz002.4daf8b8779684220b846abe2dd533ae6.png)

可以看到main thread永不退出，被executor service里面的task给block住了。除非我们加入代码，让executor service进行shutdown，main thread才会退出：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz005.fcedf0292eb047baa2e71f3a97a0e9d7.png)

如上所示，使用「shutdown()」方法，这个任务就退出了，于是main thread也跟着退出。

我想知道上面这个场景是如何实现的，就跟踪了一下Executors的代码。首先，ExecutorService的submit方法是这样的：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz006.a8311e60cf064e6abde39dc4c7c47b33.png)

是在AbstractExecutorService里面实现的，这个submit方法里面的重点是上面这个execute方法。

跟踪进execute方法，重点是这个addWorker方法：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz007.ed4f9fe9f0ce45dca0950c135a1fa117.png)

再进入addWorker方法查看，重点是这里：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz008.5e23c673b01c4a0a9facbce70ee560fa.png)

可以看到创建了一个Worker的实例。创建完worker以后，就会在addWorker方法里面启动它：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz009.17b0fe895a524161a3bfe53587288882.png)

如上所示，这个t就是一个Thread实例，封装在worker里面。Worker这个class在ThreadPoolExecutor内部，代码如下：

```java
/**
 * Class Worker mainly maintains interrupt control state for
 * threads running tasks, along with other minor bookkeeping.
 * This class opportunistically extends AbstractQueuedSynchronizer
 * to simplify acquiring and releasing a lock surrounding each
 * task execution.  This protects against interrupts that are
 * intended to wake up a worker thread waiting for a task from
 * instead interrupting a task being run.  We implement a simple
 * non-reentrant mutual exclusion lock rather than use
 * ReentrantLock because we do not want worker tasks to be able to
 * reacquire the lock when they invoke pool control methods like
 * setCorePoolSize.  Additionally, to suppress interrupts until
 * the thread actually starts running tasks, we initialize lock
 * state to a negative value, and clear it upon start (in
 * runWorker).
 */
private final class Worker
	extends AbstractQueuedSynchronizer
	implements Runnable
{
	/**
	 * This class will never be serialized, but we provide a
	 * serialVersionUID to suppress a javac warning.
	 */
	private static final long serialVersionUID = 6138294804551838833L;

	/** Thread this worker is running in.  Null if factory fails. */
	final Thread thread;
	/** Initial task to run.  Possibly null. */
	Runnable firstTask;
	/** Per-thread task counter */
	volatile long completedTasks;

	/**
	 * Creates with given first task and thread from ThreadFactory.
	 * @param firstTask the first task (null if none)
	 */
	Worker(Runnable firstTask) {
		setState(-1); // inhibit interrupts until runWorker
		this.firstTask = firstTask;
		this.thread = getThreadFactory().newThread(this);
	}

	/** Delegates main run loop to outer runWorker  */
	public void run() {
		runWorker(this);
	}

	// Lock methods
	//
	// The value 0 represents the unlocked state.
	// The value 1 represents the locked state.

	protected boolean isHeldExclusively() {
		return getState() != 0;
	}

	protected boolean tryAcquire(int unused) {
		if (compareAndSetState(0, 1)) {
			setExclusiveOwnerThread(Thread.currentThread());
			return true;
		}
		return false;
	}

	protected boolean tryRelease(int unused) {
		setExclusiveOwnerThread(null);
		setState(0);
		return true;
	}

	public void lock()        { acquire(1); }
	public boolean tryLock()  { return tryAcquire(1); }
	public void unlock()      { release(1); }
	public boolean isLocked() { return isHeldExclusively(); }

	void interruptIfStarted() {
		Thread t;
		if (getState() >= 0 && (t = thread) != null && !t.isInterrupted()) {
			try {
				t.interrupt();
			} catch (SecurityException ignore) {
			}
		}
	}
}
```

可以看到它包含task和运行task所需的thread，并且它实现了Runnable接口。注意它的run方法：

```java
/** Delegates main run loop to outer runWorker  */
public void run() {
	runWorker(this);
}
```

也就是说，「runWorker」方法是worker的执行逻辑，而「runWorker」方法里面值得一看的是这里：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz010.32a695e6c2d94202a75cfe1e574cffaf.png)

这个「getTask()」有一处代码是可能block住当前thread的：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz011.8842d6b6fbca40afbb354464e33c2b35.png)

这个workQueue是BlockingQueue类型，它的「take()」方法会hold住当前thread。

但是，这个worker thread是怎样block住main thread的呢？这个要从ExecutorService的创建里面找答案：

```java
ExecutorService executorService = Executors.newSingleThreadExecutor();
```

下面是「Executors.newSingleThreadExecutor()」的代码：

```java
public static ExecutorService newSingleThreadExecutor() {
	return new FinalizableDelegatedExecutorService
		(new ThreadPoolExecutor(1, 1,
								0L, TimeUnit.MILLISECONDS,
								new LinkedBlockingQueue<Runnable>()));
}
```

注意创建的是ThreadPoolExecutor，跟踪进它的constructor：

```java
public ThreadPoolExecutor(int corePoolSize,
						  int maximumPoolSize,
						  long keepAliveTime,
						  TimeUnit unit,
						  BlockingQueue<Runnable> workQueue) {
	this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
		 Executors.defaultThreadFactory(), defaultHandler);
}
```

看到这里：

```java
Executors.defaultThreadFactory(),
```

查看这个DefaultThreadFactory，位于Executors内部：

```java
/**
 * The default thread factory
 */
static class DefaultThreadFactory implements ThreadFactory {
	private static final AtomicInteger poolNumber = new AtomicInteger(1);
	private final ThreadGroup group;
	private final AtomicInteger threadNumber = new AtomicInteger(1);
	private final String namePrefix;

	DefaultThreadFactory() {
		SecurityManager s = System.getSecurityManager();
		group = (s != null) ? s.getThreadGroup() :
							  Thread.currentThread().getThreadGroup();
		namePrefix = "pool-" +
					  poolNumber.getAndIncrement() +
					 "-thread-";
	}

	public Thread newThread(Runnable r) {
		Thread t = new Thread(group, r,
							  namePrefix + threadNumber.getAndIncrement(),
							  0);
		if (t.isDaemon())
			t.setDaemon(false);
		if (t.getPriority() != Thread.NORM_PRIORITY)
			t.setPriority(Thread.NORM_PRIORITY);
		return t;
	}
}
```

注意到这个ThreadGroup：

```java
Thread.currentThread().getThreadGroup();
```

于是学习了ThreadGroup的概念，猜测在同一个thread group的thread会互相block住。为了验证自己的想法，写了如下代码：

```java
public class PlayWithDefaultThreadFactory {
	public static void main(String[] args) {
		DefaultThreadFactory factory = new DefaultThreadFactory(); // 这个DefaultThreadFactory会把新的thread创建在main thread所属的group里。

		// 同一个thread group里面的thread执行没结束的时候，main thread不会退出，会被block住。
		Thread t = factory.newThread(() -> {
			try {
				sleep(3000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		});

		// 这个thread跑起来以后，main thread会继续执行，直到block在结束的地方，等待t里面的sleep的3秒钟完成，除非像下面这样给interrupt()。
		t.start();

	}
}
```

执行上面的代码，发现同一个thread group里面的thread会把组内的其它thread给block住（但不影响其它thread执行到结束，只是其它thread不会退出）：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz013.987e844353584b19a51e796b1ef1fda1.png)

于是在上面的代码最后加上这样一行：

```java
// 让worker thread直接退出，这样main thread就不会block在结束的位置了
t.interrupt();
```

执行代码，想法得到了验证：

![](https://raw.githubusercontent.com/liweinan/blogpicbackup/master/data/IntelliJ IDEAScreenSnapz014.570966686e374da684ccbceb761d964e.png)

通过上面的分析，学习了thread group的概念，并且学习了Executor里面一些重要的设计思想，以及Executors内部包含的一些classes，比如DefaultThreadFactory的设计。

并发库这一块主要是Doug Lea设计并实现的，代码很值得阅读和学习。












