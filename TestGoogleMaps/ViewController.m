//
//  ViewController.m
//  TestGoogleMaps
//
//  Created by appledev064 on 4/6/16.
//  Copyright © 2016 appledev064. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
@import GoogleMaps;

@interface ViewController () <GMSMapViewDelegate, GMSIndoorDisplayDelegate>

@property (weak, nonatomic) IBOutlet UILabel *messageLbl;
@property (nonatomic, strong) GMSMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
//    [self getCurrentLocation];
    [self showLeeGardenOnGoogleMap];
    [self getDirectionsFrom:@"22.278479,114.184828" to:@"22.277642,114.182926" withMode:@"walking"];
//    [self showAddMarker];
}

- (void)getCurrentLocation{
    
    GMSPlacesClient *placesClient = [[GMSPlacesClient alloc] init];
    [placesClient currentPlaceWithCallback:^(GMSPlaceLikelihoodList * _Nullable likelihoodList, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Pick Place Error %@", [error localizedDescription]);
            return;
        }
        
        if (likelihoodList != nil) {
            GMSPlace *place = [[[likelihoodList likelihoods] firstObject] place];
            if (place != nil) {
                NSLog(@"%@", place.name);
                NSLog(@"%@", [[place.formattedAddress componentsSeparatedByString:@", "] componentsJoinedByString:@"\n"]);
            }
        }
    }];
}

- (void)getDirectionsFrom:(NSString *)originStr to:(NSString *)destinationStr withMode:(NSString *)modeStr{
    
    _messageLbl.text = @"Loading";
    AFHTTPSessionManager *httpSessionMamager = [AFHTTPSessionManager manager];
    
    NSDictionary *parameters = @{@"origin": originStr, @"destination": destinationStr, @"mode": modeStr, @"key": @"AIzaSyAs697ORtYmqIGSbC6VK6BislNiEBK-bhE"};
    [httpSessionMamager GET:@"https://maps.googleapis.com/maps/api/directions/json" parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {

        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        _messageLbl.text = @"Success";
        
        [self getPolyLineWithDirectionResponse:responseObject];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}

- (void)getPolyLineWithDirectionResponse:(id)responseObject{
 
    NSArray *routes = [responseObject valueForKey:@"routes"];
    NSDictionary *legs = [routes firstObject];
    NSDictionary *temp = [legs objectForKey:@"overview_polyline"];
    
    NSString *end_points=[temp objectForKey:@"points"];
    
    NSArray *routeLines = [self decodePolyLine:[end_points mutableCopy]];
    [self updateRouteLines:routeLines];
}

- (void)updateRouteLines:(NSArray*)routes
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRouteLines:routes];
        });
        return;
    }
    
    if (!routes || routes.count < 1) {
        
        NSLog(@"Routes Calculate failed");
        return;
    }
    
    GMSMutablePath *path = [GMSMutablePath path];
    for (int j = [routes count]; j > 0; j--)
    {
        CLLocation *pnts = [routes objectAtIndex:j-1];
        
        if (!pnts) {
            NSLog(@"single routes points failed drawing.");
            continue;
        }
        
        [path addLatitude:pnts.coordinate.latitude longitude:pnts.coordinate.longitude];
        
    }
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeColor = [UIColor blueColor];
    polyline.strokeWidth = 5.f;
    polyline.map = _mapView;
}

- (NSMutableArray *)decodePolyLine: (NSMutableString *)encoded {
    
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, [encoded length])];
    
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    
    while (index < len) {
        
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        
        do {
            
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        
        do {
            
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude1 = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude1 = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        printf("[%f,", [latitude1 doubleValue]);
        printf("%f]", [longitude1 doubleValue]);
        CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:[latitude1 floatValue] longitude:[longitude1 floatValue]];
        
        [array addObject:loc1];
    }
    
    return array;
}

- (void)drawDirections{
    
    GMSMutablePath *path = [GMSMutablePath path];
    [path addLatitude:-33.866 longitude:151.195]; // Sydney
    [path addLatitude:-18.142 longitude:178.431]; // Fiji
    [path addLatitude:21.291 longitude:-157.821]; // Hawaii
    [path addLatitude:37.423 longitude:-122.091]; // Mountain View
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeColor = [UIColor blueColor];
    polyline.strokeWidth = 5.f;
    polyline.map = _mapView;
}

- (void)showLeeGardenOnGoogleMap{
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:22.2785 longitude:114.1848 zoom:200];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    
    _mapView.myLocationEnabled = YES;
    _mapView.delegate = self;
    _mapView.indoorDisplay.delegate = self;
    self.view = _mapView;
}

- (void)showAddMarker{
    
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                            longitude:151.20
                                                                 zoom:6];
    GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView.myLocationEnabled = YES;
    self.view = mapView;
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(-33.86, 151.20);
    marker.title = @"Sydney";
    marker.snippet = @"Australia";
    marker.map = mapView;
}

#pragma mark - GMSMapViewDelegate
- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate{
    
    double lat = coordinate.latitude;
    double longt = coordinate.longitude;
    NSLog(@"latitude: %f", lat);
    NSLog(@"longitude: %f", longt);
}

@end
