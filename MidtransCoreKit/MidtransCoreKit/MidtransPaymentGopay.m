//
//  MidtransPaymentGopay.m
//  MidtransCoreKit
//
//  Created by Tommy.Yohanes on 14/11/17.
//  Copyright © 2017 Midtrans. All rights reserved.
//

#import "MidtransPaymentGopay.h"

@implementation MidtransPaymentGopay

- (NSDictionary *)dictionaryValue {
    return @{@"payment_type":MIDTRANS_PAYMENT_GOPAY};
}

@end
