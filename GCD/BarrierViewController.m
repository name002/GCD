//
//  BarrierViewController.m
//  GCD
//
//  Created by elong on 2017/9/13.
//  Copyright © 2017年 QCxy. All rights reserved.
//

#import "BarrierViewController.h"

@interface BarrierViewController ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t CONCURRENT_QUEUE;
#else
@property (nonatomic, assign) dispatch_queue_t queueB;
#endif

@end

@implementation BarrierViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    _CONCURRENT_QUEUE = dispatch_queue_create("com.qcxy.CONCURRENT_QUEUE", DISPATCH_QUEUE_CONCURRENT);
    [self addButtonWithFrame:CGRectMake(30, 70, 200, 40) title:@"barrier" select:@selector(barrier)];
    [self addButtonWithFrame:CGRectMake(30, 120, 200, 40) title:@"serialQueue" select:@selector(serialQueue)];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)barrier
{
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
}

- (void)serialQueue
{
    dispatch_queue_t queue = dispatch_queue_create("com.qcxy.QUEUE_SERIAL", DISPATCH_QUEUE_SERIAL);
    //    queue = dispatch_get_main_queue();
    __block int last = -1;
    for (int i =  0 ; i < 100000 ; i++)
    {
        dispatch_async(queue, ^{
            NSLog(@"add %d",i);
            if (i==last+1) {
                //
            }else{
                NSLog(@"乱序");
            }
            last = i;
        });
    }
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
