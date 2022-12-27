//
//  BridgingHeader.h
//  TheChan
//
//  Created by Вадим Новосельцев on 04.12.16.
//  Copyright © 2016 ACEDENED Software. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import "CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h"
#import "YYText/YYText.h"

@interface YYTextView (UpdateLayout)
-(void) _update;
- (void)setDebugEnabled_:(BOOL)enabled;
@end
