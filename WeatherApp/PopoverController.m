//
//  PopoverController.m
//  WeatherApp
//
//  Created by Pomme on 10/12/16.
//  Copyright © 2016 Yuanjie Xie. All rights reserved.
//

#import "PopoverController.h"

@interface PopoverController ()

@end

@implementation PopoverController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

// update unit when unit segment tapped
- (IBAction)unitSegmentTapped:(id)sender {
    NSString *unitStr;
    if (self.unitSegment.selectedSegmentIndex == 1) {
        unitStr = @"C"; // unit ºF
    } else {
        unitStr = @"F";// unit ºC
    }
    NSLog(@"%@", unitStr);
    NSDictionary *dic = @{ @"unit": unitStr,};
    NSLog(@"%@", dic);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"UnitNotification" object:self userInfo:dic];
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
