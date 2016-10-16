//
//  ViewController.h
//  WeatherApp
//
//  Created by Pomme on 10/11/16.
//  Copyright © 2016 Yuanjie Xie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "DailyTableViewCell.h"
#import "HourlyCollectionViewCell.h"

@interface ViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, CLLocationManagerDelegate>


@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSMutableArray *forecastArray;
@property (strong, nonatomic) NSMutableArray *hourlyArray;
@property (weak, nonatomic) NSString *zipcode;
@property (weak, nonatomic) NSString *latitudeStr;
@property (weak, nonatomic) NSString *longitudeStr;
@property (weak, nonatomic) NSString *unitStr;
@property (weak, nonatomic) UILabel *hourlyTempLabel;
@property (weak, nonatomic) UILabel *dailyHigh;
@property (weak, nonatomic) UILabel *dailyLow;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;


@end

