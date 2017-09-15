//
//  DeadlockViewController.m
//  GCD
//
//  Created by elong on 2017/9/13.
//  Copyright © 2017年 QCxy. All rights reserved.
//

#import "DeadlockViewController.h"

@interface DeadlockViewController ()

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t queueA;
#else
@property (nonatomic, assign) dispatch_queue_t queueA;
#endif

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t queueB;
#else
@property (nonatomic, assign) dispatch_queue_t queueB;
#endif

@end

@implementation DeadlockViewController


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
