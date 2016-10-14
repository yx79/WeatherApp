//
//  ViewController.m
//  WeatherApp
//
//  Created by Pomme on 10/11/16.
//  Copyright © 2016 Yuanjie Xie. All rights reserved.
//

#import "ViewController.h"
#define API_KEY_ID @"Your own API key ID here";

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UITableView *dailyTableView;
@property (weak, nonatomic) IBOutlet UICollectionView *hourlyColloectionView;
@property (weak, nonatomic) IBOutlet UILabel *currentTemLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentIcon;
@property (weak, nonatomic) IBOutlet UILabel *currentWeatherLabel;
@property (weak, nonatomic) IBOutlet UILabel *todayHighLabel;
@property (weak, nonatomic) IBOutlet UILabel *todayLowLabel;
@property (weak, nonatomic) IBOutlet UILabel *todayLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;




@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationLabel.text = @"Loading...";

    // fetch data with Grand Central Dispatch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Set up the location Manager
            [self setupLocationManager];
        });
    });
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(receiveNotification:) name:@"UnitNotification" object:nil];
    
    //remove the separator line in a UITableView
    self.dailyTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setupLocationManager {
    // Set up the location Manager
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 1000.0; // meters
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate



- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        self.longitudeStr = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.latitudeStr = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        NSLog(@"%@", self.longitudeStr);
        NSString *apiKeyStr = API_KEY_ID;
        NSString *urlRequestTemple = @"http://api.wunderground.com/api/%@/%@/q/%@,%@.json";
        [self fetchCurrentJSONfromInternet: [NSString stringWithFormat:urlRequestTemple, apiKeyStr, @"conditions", self.latitudeStr, self.longitudeStr]];
        [self fetchHourlyForecastJSONfromInternet: [NSString stringWithFormat:urlRequestTemple, apiKeyStr, @"hourly", self.latitudeStr, self.longitudeStr]];
        [self fetchTenDayJSONfromInternet: [NSString stringWithFormat:urlRequestTemple, apiKeyStr, @"forecast10day", self.latitudeStr, self.longitudeStr]];
        [self fetchTodayForecastJSONfromInternet];
        [self.dailyTableView reloadData];
        [self.hourlyColloectionView reloadData];
    } else {
        [self zipcodeAlertView];
    }
}
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if ((currentStatus != kCLAuthorizationStatusAuthorizedWhenInUse) && (currentStatus != kCLAuthorizationStatusAuthorizedAlways) && currentStatus == kCLAuthorizationStatusDenied) {
        [self zipcodeAlertView];
    }
}



// Current (top)
- (void)fetchCurrentJSONfromInternet: (NSString *)urlStr {
    // Url fetch data
    NSURL *url = [NSURL URLWithString:urlStr];
    NSLog(@"\nURL: %@", urlStr);
    NSData *currentData = [NSData dataWithContentsOfURL:url options:kNilOptions error:nil];
    
    /*
    // using local json file to test
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"current" ofType:@"json"];
    //NSLog(@"%@", filePath);
    NSData *currentData = [NSData dataWithContentsOfFile: filePath];
     */
    
    NSDictionary *mainDic = [NSJSONSerialization JSONObjectWithData:currentData options:NSJSONReadingAllowFragments error:nil];
    NSDictionary *currentDic = [mainDic objectForKey:@"current_observation"];
    
    // lookup the Weather type in JSON file
    NSString *currentWeatherStr = [currentDic objectForKey:@"weather"];
    self.currentWeatherLabel.text = currentWeatherStr;
    //NSLog(@"%@", currentWeatherStr);
    
    // lookup the location temp in JSON file
    NSDictionary *locationDic = [currentDic objectForKey:@"display_location"];
    NSString *cityStr = [locationDic objectForKey:@"city"];
    self.locationLabel.text = cityStr;
    NSLog(@"%@", cityStr);
    
    // lookup the temp in JSON file
    NSNumber *currentTemNum = [currentDic objectForKey:@"temp_f"];
    int tem = [currentTemNum intValue];
    NSString *currentTemStr = [NSString stringWithFormat:@"%d", tem];
    self.currentTemLabel.text = currentTemStr;
    //NSLog(@"%@", currentTemStr);
    
    // lookup the icon and choose the Weather icon in UIImageView
    NSString *weatherIcon = [currentDic objectForKey:@"icon"];
    NSString *largeIcon = [NSString stringWithFormat:@"%@L",weatherIcon];
    self.currentIcon.image = [UIImage imageNamed:largeIcon];
    //NSLog(@"%@", weatherIcon);
}



// Hourly (middle collection view)
-(void)fetchHourlyForecastJSONfromInternet: (NSString *)urlStr  {
    
    // Url fetch data
    /*
    // read local data for development without too many APIs request
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"hourlyData" ofType:@"json"];
    NSLog(@"%@", filePath);
    NSData *hourlyNSData = [NSData dataWithContentsOfFile: filePath];
    */
    
    NSURL *url = [NSURL URLWithString:urlStr];
    //NSLog(@"\nURL: %@", urlStr);
    NSData *hourlyNSData = [NSData dataWithContentsOfURL:url options:kNilOptions error:nil];
    
    NSDictionary *hourlyDic = [NSJSONSerialization JSONObjectWithData:hourlyNSData options:NSJSONReadingAllowFragments error:nil];

    self.hourlyArray = [hourlyDic objectForKey:@"hourly_forecast"];
    //NSLog(@"%@", hourlyDic);
    //NSLog(@"All data: %lu", (unsigned long)[self.hourlyArray count]);
}

// days forecast (bottom tableView)
- (void)fetchTenDayJSONfromInternet: (NSString *)urlStr  {
    /*
    // read local data for development without too many APIs request
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"tenDayData" ofType:@"json"];
    NSLog(@"%@", filePath);
    NSData *tenDay = [NSData dataWithContentsOfFile: filePath];
    */

    // Url fetch data
    NSURL *url = [NSURL URLWithString:urlStr];
    NSLog(@"\nURL: %@", urlStr);
    NSData *tenDay = [NSData dataWithContentsOfURL:url options:kNilOptions error:nil];
    NSDictionary *mainDic = [NSJSONSerialization JSONObjectWithData:tenDay options:NSJSONReadingAllowFragments error:nil];
    NSDictionary *forecastDic = [mainDic objectForKey:@"forecast"];
    NSDictionary *simpleForecastDic = [forecastDic objectForKey:@"simpleforecast"];

    self.forecastArray = [simpleForecastDic objectForKey:@"forecastday"];
    //NSLog(@"All data: %lu", (unsigned long)[self.forecastArray count]);
}



- (void)fetchTodayForecastJSONfromInternet {
    // Display the weather info on the table view cell
    NSDictionary *weatherDic = [self.forecastArray objectAtIndex:0];
    // lookup the weekday in JSON file, and show in UILabel with tag number
    NSDictionary *weatherDate = [weatherDic objectForKey:@"date"];
    NSString *weekday = [weatherDate objectForKey:@"weekday"];
    self.todayLabel.text = weekday;
    
    // Look up high temp forecast of today
    NSDictionary *weatherHigh = [weatherDic objectForKey:@"high"];
    NSString *high = [weatherHigh objectForKey:@"fahrenheit"];
    if([self.unitStr isEqualToString:@"C"]) {
        int todayHighF = [high intValue];
        int todayHighC = (todayHighF - 32) * 5 / 9;
        high = [NSString stringWithFormat:@"%d", todayHighC];
    }
    self.todayHighLabel.text = high;
    
    // lookup the low temp in JSON file, and show in UILabel with tag number
    NSDictionary *weatherLow = [weatherDic objectForKey:@"low"];
    NSString *low = [weatherLow objectForKey:@"fahrenheit"];
    if([self.unitStr isEqualToString:@"C"]) {
        int todayLowF = [low intValue];
        int todayLowC = (todayLowF - 32) * 5 / 9;
        low = [NSString stringWithFormat:@"%d", todayLowC];
    }
    self.todayLowLabel.text = low;
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Delegate of the Daily Table View
#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // first forecast is Today, the tableView contains next 9 days
    return [self.forecastArray count] - 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DailyTableViewCell *cell = (DailyTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"dailyCell"];
    
    // Configure the daily forecast
    if (!cell) {
        cell = [[DailyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dailyCell"];
    }
    
    // start from next one (first one is today forecast)
    long index = indexPath.row + 1;
    // Display the weather info on the table view cell
    NSDictionary *weatherDic = [self.forecastArray objectAtIndex:index];

    
    // lookup the weekday in JSON file, and show in UILabel with tag number
    NSDictionary *weatherDate = [weatherDic objectForKey:@"date"];
    NSString *weekday = [weatherDate objectForKey:@"weekday"];
    UILabel *dailyCelldate = (UILabel *)[cell viewWithTag:200];
    dailyCelldate.text = weekday;
    
    
    // lookup the high temp in JSON file, and show in UILabel with tag number
    NSDictionary *weatherHigh = [weatherDic objectForKey:@"high"];
    NSString *high = [weatherHigh objectForKey:@"fahrenheit"];
    if([self.unitStr isEqualToString:@"C"]) {
        int dailyHighF = [high intValue];
        int dailyHighC = (dailyHighF - 32) * 5 / 9;
        high = [NSString stringWithFormat:@"%d", dailyHighC];
    }
    self.dailyHigh = (UILabel *)[cell viewWithTag:202];
    self.dailyHigh.text = high;

    // lookup the low temp in JSON file, and show in UILabel with tag number
    NSDictionary *weatherLow = [weatherDic objectForKey:@"low"];
    NSString *low = [weatherLow objectForKey:@"fahrenheit"];
    if([self.unitStr isEqualToString:@"C"]) {
        int dailyLowF = [low intValue];
        int dailyLowC = (dailyLowF - 32) * 5 / 9;
        low = [NSString stringWithFormat:@"%d", dailyLowC];
    }
    self.dailyLow = (UILabel *)[cell viewWithTag:203];
    self.dailyLow.text = low;

    // lookup the icon and choose the Weather icon in UIImageView
    NSString *weatherIcon = [weatherDic objectForKey:@"icon"];
    UIImageView *dailyWeather = (UIImageView *)[cell viewWithTag:201];
    dailyWeather.image = [UIImage imageNamed:weatherIcon];
    
    return cell;
}







// Delegate of the hourly Collection View

#pragma mark - UICollectionViewDataSource Methods


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.hourlyArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CollectionViewCellIdentifier = @"hourlyCell";

    HourlyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    // Display the weather info on the table view cell
    
    NSDictionary *weatherDic = [self.hourlyArray objectAtIndex:indexPath.row];
    
    
    
    // lookup the time  in JSON file, and show in UILabel with tag number
    NSDictionary *weatherTime = [weatherDic objectForKey:@"FCTTIME"];
    NSNumber *hourNum = [weatherTime objectForKey:@"hour"];
    int hourInt = [hourNum intValue];
    if (hourInt > 12) {
        hourInt = hourInt - 12;
    }
    NSString *ampmStr = [weatherTime objectForKey:@"ampm"];
    NSString *hourAMPMStr = [NSString stringWithFormat:@"%d%@", hourInt, ampmStr];
    //NSLog(@"%@", hourAMPMStr);
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:100];
    timeLabel.text = hourAMPMStr;
    
    // lookup the icon and choose the Weather icon in UIImageView
    NSString *weatherIcon = [weatherDic objectForKey:@"icon"];
    //NSLog(@"%@", weatherIcon);
    UIImageView *hourlyWeather = (UIImageView *)[cell viewWithTag:101];
    hourlyWeather.image = [UIImage imageNamed:weatherIcon];
    
    // lookup the Temp in JSON file, and show in UILabel with tag number
    NSDictionary *weatherTemp = [weatherDic objectForKey:@"temp"];
    NSString *tempStr = [weatherTemp objectForKey:@"english"];
    if([self.unitStr isEqualToString:@"C"]) {
        int hourlyF = [tempStr intValue];
        int hourlyC = (hourlyF - 32) * 5 / 9;
        tempStr = [NSString stringWithFormat:@"%d", hourlyC];
    }
    self.hourlyTempLabel = (UILabel *)[cell viewWithTag:102];
    self.hourlyTempLabel.text = tempStr;
    
    return cell;
}







// Edit button Tapped to show Alert View
- (IBAction)editButtonTapped:(id)sender {
    [self zipcodeAlertView];
}

- (void)zipcodeAlertView {
    UIAlertController *editAC = [UIAlertController alertControllerWithTitle:@"Edit Location" message:@"Enter your postal code below:" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.currentTemLabel.text = @"";
        self.zipcode = ((UITextField *)[editAC.textFields objectAtIndex:0]).text;
        NSLog(@"%@", self.zipcode);
        if([self.zipcode length] != 5 || self.zipcode == nil) {
            UIAlertController *wrongZipcodeAC = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please enter correct 5 digit postal code below:" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *tryAction = [UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self zipcodeAlertView];
                self.todayLowLabel.text = @"";
                self.todayHighLabel.text = @"";
                //self.currentTemLabel.text = @"";
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                //self.currentTemLabel.text = @"";
            }];
            [wrongZipcodeAC addAction:cancelAction];
            [wrongZipcodeAC addAction:tryAction];
            [self presentViewController:wrongZipcodeAC animated:YES completion:nil];
            
        }
        // Update
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchCurrentJSONfromInternet: [NSString stringWithFormat:@"http://api.wunderground.com/api/7dfb3c43f027b627/conditions/q/%@.json", self.zipcode]];
                [self fetchHourlyForecastJSONfromInternet: [NSString stringWithFormat:@"http://api.wunderground.com/api/7dfb3c43f027b627/hourly/q/%@.json", self.zipcode]];
                [self fetchTenDayJSONfromInternet: [NSString stringWithFormat:@"http://api.wunderground.com/api/7dfb3c43f027b627/forecast10day/q/%@.json", self.zipcode]];
                [self fetchTodayForecastJSONfromInternet];
                
                [self.dailyTableView reloadData];
                [self.hourlyColloectionView reloadData];
            });
        });
    }];
    [editAC addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"e.g. 10010";
        textField.textColor = [UIColor grayColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [textField setKeyboardType:UIKeyboardTypeDecimalPad];
    }];
    [editAC addAction:okAction];
    [self presentViewController:editAC animated:YES completion:nil];
}





// Setting Button Tapped to send Popover View
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"popover"]) {
        UIViewController *settingVC = segue.destinationViewController;
        settingVC.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20.0, 200.0);
        UIPopoverPresentationController *ppc = settingVC.popoverPresentationController;
        if (ppc) {
            if ([sender isKindOfClass:[UIButton class]]) {
                //  the popover is being triggered by setting UIButton 
                ppc.sourceView = (UIButton *)sender;
                ppc.sourceRect = [(UIButton *)sender bounds];
            }
            ppc.delegate = self;
        }
    }
}
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}



// receive the notification from Popover View
-(void)receiveNotification:(NSNotification*)notification
{
    if ([notification.name isEqualToString:@"UnitNotification"])
    {
        NSDictionary* userInfo = notification.userInfo;
        self.unitStr = [userInfo objectForKey:@"unit"];
        NSLog (@"Successfully received test notification!\n %@", self.unitStr);
        
        // update the temp
        [self.dailyTableView reloadData];
        [self.hourlyColloectionView reloadData];
        [self fetchTodayForecastJSONfromInternet];
    }
}


@end
