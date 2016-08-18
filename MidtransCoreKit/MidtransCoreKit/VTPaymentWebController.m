//
//  VTDirectDebitController.m
//  MidtransCoreKit
//
//  Created by Nanang Rafsanjani on 6/16/16.
//  Copyright © 2016 Veritrans. All rights reserved.
//

#import "VTPaymentWebController.h"
#import "VTHelper.h"
#import "VTConstant.h"

@interface VTPaymentWebController () <UIWebViewDelegate, UIAlertViewDelegate>
@property (nonatomic) UIWebView *webView;
@property (nonatomic) NSString *paymentIdentifier;
@property (nonatomic, readwrite) VTTransactionResult *result;
@end

@implementation VTPaymentWebController

- (instancetype _Nonnull)initWithTransactionResult:(VTTransactionResult * _Nonnull)result paymentIdentifier:(NSString *_Nonnull)paymentIdentifier {
    if (self = [super init]) {
        self.result = result;
        self.paymentIdentifier = paymentIdentifier;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.paymentIdentifier isEqualToString:VT_PAYMENT_BRI_EPAY]) {
        self.title = @"BRI E-Pay";
    }
    else if ([self.paymentIdentifier isEqualToString:VT_PAYMENT_BCA_KLIKPAY]) {
        self.title = @"BCA KlikPay";
    }
    else if ([self.paymentIdentifier isEqualToString:VT_PAYMENT_MANDIRI_ECASH]) {
        self.title = @"Mandiri E-Cash";
    }
    else if ([self.paymentIdentifier isEqualToString:VT_PAYMENT_CIMB_CLICKS]) {
        self.title = @"CIMB Clicks";
    }
    
    self.webView = [UIWebView new];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePressed:)];
    
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:0 views:@{@"view":self.webView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:0 views:@{@"view":self.webView}]];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.result.redirectURL]];
}

- (void)closePressed:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Konfirmasi Navigasi"
                                                    message:@"Apakah anda yakin akan meninggalkan halaman ini?"
                                                   delegate:self
                                          cancelButtonTitle:@"Tidak"
                                          otherButtonTitles:@"Ya", nil];
    [alert show];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ([self.delegate respondsToSelector:@selector(webPaymentController:transactionError:)]) {
        [self.delegate webPaymentController:self transactionError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    NSURLRequest *request = webView.request;
    
    if ([self.paymentIdentifier isEqualToString:VT_PAYMENT_BCA_KLIKPAY]) {
        NSDictionary *params = [self dictionaryFromQueryString:request.URL.query];
        if (params && params[@"id"]) {
            if ([self.delegate respondsToSelector:@selector(webPaymentController_transactionFinished:)]) {
                [self.delegate webPaymentController_transactionFinished:self];
            }
        }
    }
    else {
        NSString *requestBodyString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        requestBodyString = [[requestBodyString stringByReplacingOccurrencesOfString:@"+"
                                                                          withString:@" "]
                             stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary *body = [self dictionaryFromQueryString:requestBodyString];
        
        if (body[@"response"]) {
            NSData *data = [body[@"response"] dataUsingEncoding:NSUTF8StringEncoding];
            id response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if ([response[@"transaction_status"] isEqualToString:VT_TRANSACTION_STATUS_DENY]) {
                NSError *error = [self transactionError];
                if ([self.delegate respondsToSelector:@selector(webPaymentController:transactionError:)]) {
                    [self.delegate webPaymentController:self transactionError:error];
                }
            }
            else {
                if ([self.delegate respondsToSelector:@selector(webPaymentController_transactionFinished:)]) {
                    [self.delegate webPaymentController_transactionFinished:self];
                }
            }
        }
    }
}

- (NSError *)transactionError {
    NSInteger canceledDirectDebitErrorCode = -31;
    NSError *error = [[NSError alloc] initWithDomain:VT_ERROR_DOMAIN code:canceledDirectDebitErrorCode userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Transaction canceled by user", nil)}];
    return error;
}

- (NSDictionary *)dictionaryFromQueryString:(NSString *)queryString {
    NSArray *urlComponents = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryStringDictionary = [NSMutableDictionary new];
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        [queryStringDictionary setObject:value forKey:key];
    }
    return queryStringDictionary;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([self.delegate respondsToSelector:@selector(webPaymentController_transactionPending:)]) {
            [self.delegate webPaymentController_transactionPending:self];
        }
    }
}

@end
