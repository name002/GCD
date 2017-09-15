//
//  SemaphoreViewController.m
//  GCD
//
//  Created by elong on 2017/9/13.
//  Copyright © 2017年 QCxy. All rights reserved.
//

#import "SemaphoreViewController.h"

@interface SemaphoreViewController ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t CONCURRENT_QUEUE;
#else
@property (nonatomic, assign) dispatch_queue_t queueB;
#endif

@end

@implementation SemaphoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    _CONCURRENT_QUEUE = dispatch_queue_create("com.qcxy.CONCURRENT_QUEUE", DISPATCH_QUEUE_CONCURRENT);
    
    [self addButtonWithFrame:CGRectMake(30, 70, 200, 40) title:@"noSemaphore" select:@selector(noSemaphore)];
    [self addButtonWithFrame:CGRectMake(30, 130, 200, 40) title:@"semaphore" select:@selector(semaphore)];
    
}

- (void)addButtonWithFrame:(CGRect)frame title:(NSString *)title select:(SEL)select
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:button];
    
    button.frame = frame;
    button.layer.borderColor = [UIColor greenColor].CGColor;
    button.layer.borderWidth = 1;
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button addTarget:self action:select forControlEvents:UIControlEventTouchUpInside];
}

- (void)noSemaphore
{
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
////    queue = dispatch_get_main_queue();
//    __block int last = -1;
//    for (int i =  0 ; i < 10000 ; i++)
//    {
//        dispatch_async(queue, ^{
//            NSLog(@"add %d",i);
//            if (i==last+1) {
//                //
//            }else{
//                NSLog(@"乱序");
//            }
//            last = i;
//        });
//    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableArray *array = [[NSMutableArray alloc] init];
    dispatch_group_t group = dispatch_group_create();
    __block int last = -1;
    for(int i = 0; i< 100000; ++i) {
        dispatch_group_async(group, queue, ^{
            NSLog(@"add %d",i);
            [array addObject:[NSNumber numberWithInt:i]];
            if (i==last+1) {
                //
            }else{
                NSLog(@"乱序");
            }
            last = i;

        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"array:%@",array);
}

- (void)semaphore
{
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
//    // 创建队列组
//    dispatch_group_t group = dispatch_group_create();
//    // 创建信号量，并且设置值为10
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
////    queue = _CONCURRENT_QUEUE;
//    __block int last = -1;
//    for (int i = 0; i < 10000; i++)
//    {   // 由于是异步执行的，所以每次循环Block里面的dispatch_semaphore_signal根本还没有执行就会执行dispatch_semaphore_wait，从而semaphore-1.当循环10此后，semaphore等于0，则会阻塞线程，直到执行了Block的dispatch_semaphore_signal 才会继续执行
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        dispatch_group_async(group, queue, ^{
//            NSLog(@"%i",i);
//            if (i==last+1) {
//                //
//            }else{
//                NSLog(@"乱序");
//            }
//            last = i;
////            sleep(1);//加睡眠还是会乱序，除非睡眠时间变长2秒甚至更多
//            // 每次发送信号则semaphore会+1，
//            dispatch_semaphore_signal(semaphore);
//        });
//    }
    
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
//    __block int last = -1;
//    for (int i =  0 ; i < 10000 ; i++)
//    {
//        dispatch_async(queue, ^{
//            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//            NSLog(@"add %d",i);
//            if (i==last+1) {
//                //
//            }else{
//                NSLog(@"乱序");
//            }
//            last = i;
//            dispatch_semaphore_signal(semaphore);
//        });
//    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
