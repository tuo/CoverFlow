//
//  Created by tuo on 4/1/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "RootViewController.h"
#import "CoverFlowView.h"


@implementation RootViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }

    return self;
//To change the template use AppCode | Preferences | File Templates.
}

- (void)viewDidLoad {
    [super viewDidLoad];  //To change the template use AppCode | Preferences | File Templates.

    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.frame = CGRectMake(0, 0, 320, 460);

    NSMutableArray *sourceImages = [NSMutableArray arrayWithCapacity:20];
    for (int i = 0; i <20 ; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i]];
        [sourceImages addObject:image];
    }

    //CoverFlowView *coverFlowView = [CoverFlowView coverFlowViewWithFrame: frame andImages:_arrImages sidePieces:6 sideScale:0.35 middleScale:0.6];
    CoverFlowView *coverFlowView = [CoverFlowView coverFlowViewWithFrame:self.view.frame andImages:sourceImages sideImageCount:6 sideImageScale:0.35 middleImageScale:0.6];
    [self.view addSubview:coverFlowView];


}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

@end