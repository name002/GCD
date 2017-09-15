//
//  ViewController.m
//  GCD
//
//  Created by elong on 2017/9/13.
//  Copyright © 2017年 QCxy. All rights reserved.
//

#import "ViewController.h"
#import "DeadlockViewController.h"
#import "SemaphoreViewController.h"
#import "BarrierViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *itemAry;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.itemAry = [NSArray arrayWithObjects:@"Deadlock",@"Semaphore",@"Barrier", nil];
    
    int topSpace = 20;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topSpace, self.view.frame.size.width, self.view.frame.size.height-topSpace) style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _itemAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellId"];
        
    }
    NSUInteger rowNum = indexPath.row;
    cell.textLabel.text = [_itemAry objectAtIndex:rowNum];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            DeadlockViewController * viewController = [[DeadlockViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        case 1:
        {
            SemaphoreViewController * viewController = [[SemaphoreViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
        case 2:
        {
            BarrierViewController * viewController = [[BarrierViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
