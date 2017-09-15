# GCD
[Cocoa 并发编程](https://hit-alibaba.github.io/interview/iOS/Cocoa-Touch/Multithreading.html)
Cocoa 中封装了 NSThread, NSOperation, GCD 三种多线程编程方式

###NSThread

NSThread 是一个控制线程执行的对象，通过它我们可以方便的得到一个线程并控制它。NSThread 的线程之间的并发控制，是需要我们自己来控制的，可以通过 NSCondition 实现。它的缺点是需要自己维护线程的生命周期和线程的同步和互斥等，优点是轻量，灵活。

###NSOperation

NSOperation 是一个抽象类，它封装了线程的细节实现，不需要自己管理线程的生命周期和线程的同步和互斥等。只是需要关注自己的业务逻辑处理，需要和 NSOperationQueue 一起使用。使用 NSOperation 时，你可以很方便的设置线程之间的依赖关系。这在略微复杂的业务需求中尤为重要。

###GCD

GCD(Grand Central Dispatch) 是 Apple 开发的一个多核编程的解决方法。在 iOS4.0 开始之后才能使用。GCD 是一个可以替代 NSThread 的很高效和强大的技术。当实现简单的需求时，GCD 是一个不错的选择。

在现代 Objective-C 中，苹果已经不推荐使用 NSThread 来进行并发编程，而是推荐使用 GCD 和 NSOperation，具体的迁移文档参见 Migrating Away from Threads。下面我们对 GCD 和 NSOperation 的用法进行简单介绍。

#Grand Central Dispatch(GCD)
Grand Central Dispatch(GCD) 是苹果在 Mac OS X 10.6 以及 iOS 4.0 开始引入的一个高性能并发编程机制，底层实现的库名叫 libdispatch。由于它确实很好用，libdispatch 已经被移植到了 FreeBSD 上，Linux 上也有 port 过去的 libdispatch 实现。

GCD 主要的功劳在于把底层的实现隐藏起来，提供了很简洁的面向“任务” 的编程接口，GCD 底层实现仍然依赖于线程，但是使用 GCD 时完全不需要考虑下层线程的有关细节（创建任务比创建线程简单得多），GCD 会自动对任务进行调度，以尽可能地利用处理器资源。

几个概念：
* Dispatch Queue：Dispatch Queue 顾名思义，是一个用于维护任务的队列，它可以接受任务（即可以将一个任务加入某个队列）然后在适当的时候执行队列中的任务。
* Dispatch Sources：Dispatch Source 允许我们把任务注册到系统事件上，例如 socket 和文件描述符，类似于 Linux 中 epoll 的作用
* Dispatch Groups：Dispatch Groups 可以让我们把一系列任务加到一个组里，组中的每一个任务都要等待整个组的所有任务都结束之后才结束，类似 pthread_join 的功能
* Dispatch Semaphores：这个更加顾名思义，就是大家都知道的信号量了，可以让我们实现更加复杂的并发控制，防止资源竞争

这些东西中最经常用到的是 Dispatch Queue。之前提到 Dispatch Queue 就是一个类似队列的数据结构，而且是 FIFO(First In, First Out)队列，因此任务开始执行的顺序，就是你把它们放到 queue 中的顺序。GCD 中的队列有下面三种：

1. Serial （串行队列） 串行队列中任务会按照添加到 queue 中的顺序一个一个执行。串行队列在前一个任务执行之前，后一个任务是被阻塞的，可以利用这个特性来进行同步操作。

我们可以创建多个串行队列，这些队列中的任务是串行执行的，但是这些队列本身可以并发执行。例如有四个串行队列，有可能同时有四个任务在并行执行，分别来自这四个队列。

2. Concurrent（并行队列） 并行队列，也叫 global dispatch queue，可以并发地执行多个任务，但是任务开始的顺序仍然是按照被添加到队列中的顺序。具体任务执行的线程和任务执行的并发数，都是由 GCD 进行管理的。

在 iOS 5 之后，我们可以创建自己的并发队列。系统已经提供了四个全局可用的并发队列，后面会讲到。

3. Main Dispatch Queue（主队列） 主队列是一个全局可见的串行队列，其中的任务会在主线程中执行。主队列通过与应用程序的 runloop 交互，把任务安插到 runloop 当中执行。因为主队列比较特殊，其中的任务确定会在主线程中执行，通常主队列会被用作同步的作用。


#自己创建的队列与系统队列有什么不同？
事实上，我们自己创建的队列，最终会把任务分配到系统提供的主队列和四个全局的并行队列上，这种操作叫做 Target queues。具体来说，我们创建的串行队列的 target queue 就是系统的主队列，我们创建的并行队列的 target queue 默认是系统 default 优先级的全局并行队列。所有放在我们创建的队列中的任务，最终都会到 target queue 中完成真正的执行。

那岂不是自己创建队列就没有什么意义了？其实不是的。通过我们自己创建的队列，以及 dispatch_set_target_queue 和 barrier 等操作，可以实现比较复杂的任务之间的同步，可以参考[这里](http://blog.csdn.net/growinggiant/article/details/41077221) 和 [这里](http://www.humancode.us/2014/08/14/target-queues.html)。

通常情况下，对于串行队列，我们应该自己创建，对于并行队列，就直接使用系统提供的 Default 优先级的 queue。

**注意**：对于 ```dispatch_barrier``` 系列函数来说，传入的函数应当是**自己创建**的并行队列，否则 barrier 将失去作用。详情请参考苹果文档。

#创建的 Queue 需要释放吗？
在 iOS6 之前，使用 ```dispatch_queue_create``` 创建的 queue 需要使用 ```dispatch_retain``` 和 ```dispatch_release``` 进行管理，在 iOS 6 系统把 ```dispatch queue``` 也纳入了 ARC 管理的范围，就不需要我们进行手动管理了。使用这两个函数会导致报错。

iOS6 上这个改变，把 dispatch queue 从原来的非 OC 对象（原生 C 指针），变成了 OC 对象，也带来了代码上的一些兼容性问题。在 iOS5 上需要使用 assign 来修饰 queue 对象：
```
@property (nonatomic, assign) dispatch_queue_t queue;
```
到 iOS6 以上就需要使用 strong 或者 weak 来修饰，不然会报错：
```
@property (nonatomic, strong) dispatch_queue_t queue;
```
当出现兼容性问题的时候，需要根据情况来修改代码，或者改变所 target 的 iOS 版本。

#GCD 与 NSOperation 的对比

这是面试中经常会问到的一点，这两个都很常用，也都很强大。对比它们可以从下面几个角度来说：

* 首先要明确一点，NSOperationQueue 是基于 GCD 的更高层的封装，从 OS X 10.10 开始可以通过设置 ```underlyingQueue``` 来把 operation 放到已有的 dispatch queue 中。
* 从易用性角度，GCD 由于采用 C 风格的 API，在调用上比使用面向对象风格的 NSOperation 要简单一些。
* 从对任务的控制性来说，NSOperation 显著得好于 GCD，和 GCD 相比支持了 Cancel 操作（注：在 iOS8 中 GCD 引入了 ```dispatch_block_cancel``` 和 ```dispatch_block_testcancel```，也可以支持 Cancel 操作了），支持任务之间的依赖关系，支持同一个队列中任务的优先级设置，同时还可以通过 KVO 来监控任务的执行情况。这些通过 GCD 也可以实现，不过需要很多代码，使用 NSOperation 显得方便了很多。
* 从第三方库的角度，知名的第三方库如 AFNetworking 和 SDWebImage 背后都是使用 NSOperation，也从另一方面说明对于需要复杂并发控制的需求，NSOperation 是更好的选择（当然也不是绝对的，例如知名的 [Parse SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) 就完全没有使用 NSOperation，全部使用 GCD，其中涉及到大量的 GCD 高级用法，[这里](https://github.com/ChenYilong/ParseSourceCodeStudy)有相关解析）。

#Dispatch IO 文件操作
[细说GCD（Grand Central Dispatch）如何用](https://github.com/ming1016/study/wiki/细说GCD（Grand-Central-Dispatch）如何用#dispatch-io-文件操作)

dispatch io读取文件的方式类似于下面的方式，多个线程去读取文件的切片数据，对于大的数据文件这样会比单线程要快很多。

```
dispatch_async(queue,^{/*read 0-99 bytes*/});
dispatch_async(queue,^{/*read 100-199 bytes*/});
dispatch_async(queue,^{/*read 200-299 bytes*/});
```
- dispatch_io_create：创建dispatch io
- dispatch_io_set_low_water：指定切割文件大小
- dispatch_io_read：读取切割的文件然后合并。

苹果系统日志API里用到了这个技术，可以在这里查看：https://github.com/Apple-FOSS-Mirror/Libc/blob/2ca2ae74647714acfc18674c3114b1a5d3325d7d/gen/asl.c
```
pipe_q = dispatch_queue_create("PipeQ", NULL);
//创建
pipe_channel = dispatch_io_create(DISPATCH_IO_STREAM, fd, pipe_q, ^(int err){
close(fd);
});

*out_fd = fdpair[1];
//设置切割大小
dispatch_io_set_low_water(pipe_channel, SIZE_MAX);

dispatch_io_read(pipe_channel, 0, SIZE_MAX, pipe_q, ^(bool done, dispatch_data_t pipedata, int err){
if (err == 0)
{
size_t len = dispatch_data_get_size(pipedata);
if (len > 0)
{
//对每次切块数据的处理
const char *bytes = NULL;
char *encoded;
uint32_t eval;

dispatch_data_t md = dispatch_data_create_map(pipedata, (const void **)&bytes, &len);
encoded = asl_core_encode_buffer(bytes, len);
asl_msg_set_key_val(aux, ASL_KEY_AUX_DATA, encoded);
free(encoded);
eval = _asl_evaluate_send(NULL, (aslmsg)aux, -1);
_asl_send_message(NULL, eval, aux, NULL);
asl_msg_release(aux);
dispatch_release(md);
}
}

if (done)
{
//semaphore +1使得不需要再等待继续执行下去。
dispatch_semaphore_signal(sem);
dispatch_release(pipe_channel);
dispatch_release(pipe_q);
}
});
```
#Dispatch Source 用GCD监视进程
[细说GCD（Grand Central Dispatch）如何用](https://github.com/ming1016/study/wiki/细说GCD（Grand-Central-Dispatch）如何用#dispatch-io-文件操作)
Dispatch Source用于监听系统的底层对象，比如文件描述符，Mach端口，信号量等。主要处理的事件如下表

方法	                                                       | 说明
-----------------------------------------|------
DISPATCH_SOURCE_TYPE_DATA_ADD |	数据增加
DISPATCH_SOURCE_TYPE_DATA_OR |	数据OR
DISPATCH_SOURCE_TYPE_MACH_SEND |	Mach端口发送
DISPATCH_SOURCE_TYPE_MACH_RECV  |	Mach端口接收
DISPATCH_SOURCE_TYPE_MEMORYPRESSURE |	内存情况
DISPATCH_SOURCE_TYPE_PROC |	进程事件
DISPATCH_SOURCE_TYPE_READ  |	读数据
DISPATCH_SOURCE_TYPE_SIGNAL  |	信号
DISPATCH_SOURCE_TYPE_TIMER  |	定时器
DISPATCH_SOURCE_TYPE_VNODE |	文件系统变化
DISPATCH_SOURCE_TYPE_WRITE |	文件写入
##方法

- dispatch_source_create：创建dispatch source，创建后会处于挂起状态进行事件接收，需要设置事件处理handler进行事件处理。
- dispatch_source_set_event_handler：设置事件处理handler
- dispatch_source_set_cancel_handler：事件取消handler，就是在dispatch source释放前做些清理的事。
- dispatch_source_cancel：关闭dispatch source，设置的事件处理handler不会被执行，已经执行的事件handler不会取消。
```
NSRunningApplication *mail = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.mail"];
if (mail == nil) {
return;
}
pid_t const pid = mail.processIdentifier;
self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, pid, DISPATCH_PROC_EXIT, DISPATCH_TARGET_QUEUE_DEFAULT);
dispatch_source_set_event_handler(self.source, ^(){
NSLog(@"Mail quit.");
});
//在事件源传到你的事件处理前需要调用dispatch_resume()这个方法
dispatch_resume(self.source);
```
监视文件夹内文件变化
```
NSURL *directoryURL; // assume this is set to a directory
int const fd = open([[directoryURL path] fileSystemRepresentation], O_EVTONLY);
if (fd < 0) {
char buffer[80];
strerror_r(errno, buffer, sizeof(buffer));
NSLog(@"Unable to open \"%@\": %s (%d)", [directoryURL path], buffer, errno);
return;
}
dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd,
DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
dispatch_source_set_event_handler(source, ^(){
unsigned long const data = dispatch_source_get_data(source);
if (data & DISPATCH_VNODE_WRITE) {
NSLog(@"The directory changed.");
}
if (data & DISPATCH_VNODE_DELETE) {
NSLog(@"The directory has been deleted.");
}
});
dispatch_source_set_cancel_handler(source, ^(){
close(fd);
});
self.source = source;
dispatch_resume(self.source);
//还要注意需要用DISPATCH_VNODE_DELETE 去检查监视的文件或文件夹是否被删除，如果删除了就停止监听
```


#GCD使用中需要注意的问题

##声明一个dispatch的属性
[小笨狼漫谈多线程：GCD(一)](http://www.cocoachina.com/ios/20160225/15422.html)
要声明一个dispatch的属性。一般情况下我们只需要用strong即可。

```
@property (nonatomic, strong) dispatch_queue_t queue;
```
如果你是写一个framework，framework的使用者的SDK有可能还是古董级的iOS6之前。那么你需要根据OS_OBJECT_USE_OBJC做一个判断是使用strong还是assign。（一般github上的优秀第三方库都会这么做）

```
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t queue;
#else
@property (nonatomic, assign) dispatch_queue_t queue;
#endif
```

[Cocoa 并发编程](https://hit-alibaba.github.io/interview/iOS/Cocoa-Touch/Multithreading.html)也提到，参考上文 **创建的 Queue 需要释放吗？**

##死锁问题 _dispatch_barrier_sync_f_slow
[苹果文档 dispatch_sync ](https://developer.apple.com/documentation/dispatch/1452870-dispatch_sync)
Calling this function and targeting the current queue results in deadlock.
只有使用了dispatch_sync函数分发任务到 当前队列 才会导致死锁。

[dispatch_sync死锁问题研究](http://www.jianshu.com/p/44369c02b62a)
Calls to dispatch_sync() targeting the current queue will result in dead-lock. Use of dispatch_sync() is also subject to the same multi-party dead-lock problems that may result from the use of a mutex.
如果dispatch_sync()的目标queue为当前queue，会发生死锁(并行queue并不会)。使用dispatch_sync()会遇到跟我们在pthread中使用mutex锁一样的死锁问题。


```
- (void)viewDidLoad {
[super viewDidLoad];
self.view.backgroundColor = [UIColor whiteColor];
// Do any additional setup after loading the view, typically from a nib.

_queueA = dispatch_queue_create("com.qcxy.GCD_A", DISPATCH_QUEUE_SERIAL);
_queueB = dispatch_queue_create("com.qcxy.GCD_B", DISPATCH_QUEUE_SERIAL);

[self test1];
}

- (void)test1
{
NSLog(@"test3");
dispatch_sync(_queueA, ^(){
[self test2];
});
}

- (void)test2
{
NSLog(@"test3");
dispatch_sync(_queueB, ^(){
[self test3];
});
}

- (void)test3
{
NSLog(@"test3");
dispatch_sync(_queueA, ^(){
NSLog(@"do something test3");
});
}
```
[Cocoa 并发编程](https://hit-alibaba.github.io/interview/iOS/Cocoa-Touch/Multithreading.html)
![引用自《Cocoa 并发编程》的死锁说明图](http://upload-images.jianshu.io/upload_images/2061411-023afef1c1395a07.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##FMDB如何使用dispatch_queue_set_specific和dispatch_get_specific来防止死锁
[细说GCD（Grand Central Dispatch）如何用](https://github.com/ming1016/study/wiki/细说GCD（Grand-Central-Dispatch）如何用#dispatch-io-文件操作)
作用类似objc_setAssociatedObject跟objc_getAssociatedObject
```
static const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;
//创建串行队列，所有数据库的操作都在这个队列里
_queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
//标记队列
dispatch_queue_set_specific(_queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);

//检查是否是同一个队列来避免死锁的方法
- (void)inDatabase:(void (^)(FMDatabase *db))block {
FMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
}
```
##资源竞争
dispatch_barrier_async
该操作主要是为了防止资源竞争。在concurrentQueue中，所有block无序的按照所创建的线程数量同时进行。如果在concurrentQueue中有两个写入操作，而且他都是读取操作，这时两个写入操作间就会出现资源竞争，而读取操作则会读取脏数据。所以对于在concurrentQueue中不能够与其它操作并行的block就需要使用dispatch_barrier_async方法来防止资源竞争。

[GCD 深入理解：第一部分](https://github.com/nixzhu/dev-blog/blob/master/2014-04-19-grand-central-dispatch-in-depth-part-1.md)
![](http://upload-images.jianshu.io/upload_images/2061411-46484e8a2f9820fe?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
_CONCURRENT_QUEUE = dispatch_queue_create("com.qcxy.CONCURRENT_QUEUE", DISPATCH_QUEUE_CONCURRENT);

dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//用global会乱序
queue = _CONCURRENT_QUEUE;
__block int last = -1;
for (int i =  0 ; i < 100000 ; i++)
{
//The queue you specify should be a concurrent queue that you create yourself using the dispatch_queue_create function.
dispatch_barrier_async(queue, ^{
NSLog(@"add %d",i);
if (i==last+1) {
//
}else{
NSLog(@"乱序");
}
last = i;
});
}
```
如果读写操作不在concurrentQueue中，可以用serialQueue，但是dispatch_barrier_async会比serialQueue快一些。
实验数据

iPhone6s plus iOS 10.3.2
i= 100000
serialQueue用时618019-barrier用时592589= 25430毫秒
i=2000000
serialQueue用时30-barrier用时28= 2秒

[苹果文档 dispatch_barrier_async](https://developer.apple.com/documentation/dispatch/1452797-dispatch_barrier_async?language=objc)
The queue you specify should be a **concurrent queue** that you **create yourself** using the 
dispatch_queue_create
function.

###信号量
[浅谈GCD中的信号量](http://www.jianshu.com/p/04ca5470f212)

可以保证加锁、资源竞争和一定程度的同步操作，但是需要注意，操作数组类删除，或者添加数据到**新数组**的时候，当数据量大的时候，会出现乱序的问题。
```
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
dispatch_group_t group = dispatch_group_create();
__block int last = -1;
NSMutableArray *array = [[NSMutableArray alloc] init];
for (int i = 0; i < 10000; i++) {
dispatch_group_async(group,queue, ^{
// 相当于加锁
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//            NSLog(@"i = %zd semaphore = %@", i, semaphore);
NSLog(@"%d", i);
[array addObject:[NSNumber numberWithInt:i]];
if (i==last+1) {
//
}else{
NSLog(@"乱序");
}
last = i;
// 相当于解锁
dispatch_semaphore_signal(semaphore);
});
}

dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
NSLog(@"array:%@",array);
```
输出
```
2017-09-14 11:34:45.871844+0800 GCD[6578:1698130] array:(
0,
1,
2,
3,
4,
5,
7,
8,
9,
........
31,
32,
6,
33,
34,
........
```

[Parse源码浅析系列（一）---Parse的底层多线程处理思路：GCD高级用法](https://github.com/ChenYilong/ParseSourceCodeStudy/blob/master/01_Parse的多线程处理思路/Parse的底层多线程处理思路.md#使用dispatch-semaphore控制并发线程数量)
从 iOS7 升到 iOS8 后，GCD 出现了一个重大的变化：在 iOS7 时，使用 GCD 的并行队列， dispatch_async 最大开启的线程一直能控制在6、7条，线程数都是个位数，然而 iOS8后，最大线程数一度可以达到40条、50条。然而在文档上并没有对这一做法的目的进行介绍。
GCD 中 Apple 并没有提供控制并发数量的接口，而 NSOperationQueue 有，如果需要使用 GCD 实现，需要使用 GCD 的一项高级功能：Dispatch Semaphore信号量。


#引用
[Cocoa 并发编程](https://hit-alibaba.github.io/interview/iOS/Cocoa-Touch/Multithreading.html)
[GCD 深入理解：第一部分](https://github.com/nixzhu/dev-blog/blob/master/2014-04-19-grand-central-dispatch-in-depth-part-1.md)
[GCD 深入理解：第二部分](https://github.com/nixzhu/dev-blog/blob/master/2014-05-14-grand-central-dispatch-in-depth-part-2.md)
[iOS中GCD的那些坑](http://www.jianshu.com/p/6ece29c7ccc1)
[dispatch_sync死锁问题研究](http://www.jianshu.com/p/44369c02b62a)
[浅谈GCD中的信号量](http://www.jianshu.com/p/04ca5470f212)
[Parse源码浅析系列（一）---Parse的底层多线程处理思路：GCD高级用法](https://github.com/ChenYilong/ParseSourceCodeStudy/blob/master/01_Parse的多线程处理思路/Parse的底层多线程处理思路.md#使用dispatch-semaphore控制并发线程数量)
[细说GCD（Grand Central Dispatch）如何用](https://github.com/ming1016/study/wiki/细说GCD（Grand-Central-Dispatch）如何用#dispatch-io-文件操作)
