//
//  ViewController.m
//  Learn-FFmpeg
//
//  Created by Jason on 05/03/2017.
//  Copyright © 2017 Jason. All rights reserved.
//

#import "ViewController.h"
#import "KxMovieViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ViewController *vc;
//    NSString *path = @"http://192.168.5.101/~Jason/sample_iPod.m4v";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sophie" ofType:@"mov"];
    vc = [KxMovieViewController movieViewControllerWithContentPath:path parameters:nil];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
