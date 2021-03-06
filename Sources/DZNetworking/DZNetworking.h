//
//  DZNetworking.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//
//  The MIT License (MIT)
//
// Copyright (c) 2015 Dezine Zync Studios
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <Foundation/Foundation.h>

//! Project version number for DZNetworking.
FOUNDATION_EXPORT double DZNetworkingVersionNumber;

//! Project version string for DZNetworking.
FOUNDATION_EXPORT const unsigned char DZNetworkingVersionString[];

#import "Core/DZResponse.h"
#import "Core/DZURLSession.h"
#import "Core/DZUploadSession.h"
#import "Core/DZS3UploadSession.h"
#import "Core/DZOAuthSession.h"
#import "Core/DZOAuth2Session.h"
#import "Core/NSString+Coders.h"

#import "Utilities/NSString+URLExtended.h"
#import "Utilities/DZActivityIndicatorManager.h"
#import "Utilities/DZS3CredentialsManager.h"
#import "Utilities/NSString+URLExtended.h"
#import "Utilities/NSDictionary+Extend.h"

#import "ResponseParsers/DZResponseParser.h"
#import "ResponseParsers/DZJSONResponseParser.h"
