/*
 *  NSData+CommonCrypto.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>
#import "NSData+CommonCrypto.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import "zlib.h"
#import "Settings.h"

NSString * const kCommonCryptoErrorDomain = @"CommonCryptoErrorDomain";

@implementation NSError (CommonCryptoErrorDomain)

+ (NSError *) errorWithCCCryptorStatus: (CCCryptorStatus) status
{
	NSString * description = nil, * reason = nil;
	
	switch ( status )
	{
		case kCCSuccess:
			description = NSLocalizedString(@"Success", @"Error description");
			break;
			
		case kCCParamError:
			description = NSLocalizedString(@"Parameter Error", @"Error description");
			reason = NSLocalizedString(@"Illegal parameter supplied to encryption/decryption algorithm", @"Error reason");
			break;
			
		case kCCBufferTooSmall:
			description = NSLocalizedString(@"Buffer Too Small", @"Error description");
			reason = NSLocalizedString(@"Insufficient buffer provided for specified operation", @"Error reason");
			break;
			
		case kCCMemoryFailure:
			description = NSLocalizedString(@"Memory Failure", @"Error description");
			reason = NSLocalizedString(@"Failed to allocate memory", @"Error reason");
			break;
			
		case kCCAlignmentError:
			description = NSLocalizedString(@"Alignment Error", @"Error description");
			reason = NSLocalizedString(@"Input size to encryption algorithm was not aligned correctly", @"Error reason");
			break;
			
		case kCCDecodeError:
			description = NSLocalizedString(@"Decode Error", @"Error description");
			reason = NSLocalizedString(@"Input data did not decode or decrypt correctly", @"Error reason");
			break;
			
		case kCCUnimplemented:
			description = NSLocalizedString(@"Unimplemented Function", @"Error description");
			reason = NSLocalizedString(@"Function not implemented for the current algorithm", @"Error reason");
			break;
			
		default:
			description = NSLocalizedString(@"Unknown Error", @"Error description");
			break;
	}
	
	NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject: description forKey: NSLocalizedDescriptionKey];
	
	if ( reason != nil )
		[userInfo setObject: reason forKey: NSLocalizedFailureReasonErrorKey];
	
	return [NSError errorWithDomain: kCommonCryptoErrorDomain code: status userInfo: userInfo];
}

@end

#pragma mark -

@implementation NSData (CommonDigest)

- (NSData *) MD2Sum
{
	unsigned char hash[CC_MD2_DIGEST_LENGTH];
	(void) CC_MD2( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD2_DIGEST_LENGTH] );
}

- (NSData *) MD4Sum
{
	unsigned char hash[CC_MD4_DIGEST_LENGTH];
	(void) CC_MD4( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD4_DIGEST_LENGTH] );
}

- (NSData *) MD5Sum
{
	unsigned char hash[CC_MD5_DIGEST_LENGTH];
	(void) CC_MD5( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_MD5_DIGEST_LENGTH] );
}

- (NSData *) SHA1Hash
{
	unsigned char hash[CC_SHA1_DIGEST_LENGTH];
	(void) CC_SHA1( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA1_DIGEST_LENGTH] );
}

- (NSData *) SHA224Hash
{
	unsigned char hash[CC_SHA224_DIGEST_LENGTH];
	(void) CC_SHA224( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA224_DIGEST_LENGTH] );
}

- (NSData *) SHA256Hash
{
	unsigned char hash[CC_SHA256_DIGEST_LENGTH];
	(void) CC_SHA256( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA256_DIGEST_LENGTH] );
}

- (NSData *) SHA384Hash
{
	unsigned char hash[CC_SHA384_DIGEST_LENGTH];
	(void) CC_SHA384( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA384_DIGEST_LENGTH] );
}

- (NSData *) SHA512Hash
{
	unsigned char hash[CC_SHA512_DIGEST_LENGTH];
	(void) CC_SHA512( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA512_DIGEST_LENGTH] );
}

@end

@implementation NSData (CommonCryptor)

- (NSData *) AES256EncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmAES128
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) decryptedAES256DataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmAES128
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) DESEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmDES
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) decryptedDESDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmDES
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) CASTEncryptedDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self dataEncryptedUsingAlgorithm: kCCAlgorithmCAST
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

- (NSData *) decryptedCASTDataUsingKey: (id) key error: (NSError **) error
{
	CCCryptorStatus status = kCCSuccess;
	NSData * result = [self decryptedDataUsingAlgorithm: kCCAlgorithmCAST
													key: key
                                                options: kCCOptionPKCS7Padding
												  error: &status];
	
	if ( result != nil )
		return ( result );
	
	if ( error != NULL )
		*error = [NSError errorWithCCCryptorStatus: status];
	
	return ( nil );
}

@end

static void FixKeyLengths( CCAlgorithm algorithm, NSMutableData * keyData, NSMutableData * ivData )
{
	NSUInteger keyLength = [keyData length];
	switch ( algorithm )
	{
		case kCCAlgorithmAES128:
		{
			if ( keyLength < 16 )
			{
				[keyData setLength: 16];
			}
			else if ( keyLength < 24 )
			{
				[keyData setLength: 24];
			}
			else
			{
				[keyData setLength: 32];
			}
			
			break;
		}
			
		case kCCAlgorithmDES:
		{
			[keyData setLength: 8];
			break;
		}
			
		case kCCAlgorithm3DES:
		{
			[keyData setLength: 24];
			break;
		}
			
		case kCCAlgorithmCAST:
		{
			if ( keyLength < 5 )
			{
				[keyData setLength: 5];
			}
			else if ( keyLength > 16 )
			{
				[keyData setLength: 16];
			}
			
			break;
		}
			
		case kCCAlgorithmRC4:
		{
			if ( keyLength > 512 )
				[keyData setLength: 512];
			break;
		}
			
		default:
			break;
	}
	
	[ivData setLength: [keyData length]];
}

@implementation NSData (LowLevelCommonCryptor)

- (NSData *) _runCryptor: (CCCryptorRef) cryptor result: (CCCryptorStatus *) status
{
	size_t bufsize = CCCryptorGetOutputLength( cryptor, (size_t)[self length], true );
	void * buf = malloc( bufsize );
	size_t bufused = 0;
    size_t bytesTotal = 0;
	*status = CCCryptorUpdate( cryptor, [self bytes], (size_t)[self length],
							  buf, bufsize, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
    
    bytesTotal += bufused;
	
	// From Brent Royal-Gordon (Twitter: architechies):
	// Need to update buf ptr past used bytes when calling CCCryptorFinal()
    // Add "unsigned char*" 2012-09-24
	*status = CCCryptorFinal( cryptor, (unsigned char*)buf + bufused, bufsize - bufused, &bufused );
	if ( *status != kCCSuccess )
	{
		free( buf );
		return ( nil );
	}
    
    bytesTotal += bufused;
	
	return ( [NSData dataWithBytesNoCopy: buf length: bytesTotal] );
}

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
								   error: (CCCryptorStatus *) error
{
	return ( [self dataEncryptedUsingAlgorithm: algorithm
										   key: key
                          initializationVector: nil
									   options: 0
										 error: error] );
}

- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
    return ( [self dataEncryptedUsingAlgorithm: algorithm
										   key: key
                          initializationVector: nil
									   options: options
										 error: error] );
}
- (NSData*) aesEncryptWithKey:(NSString *)key initialVector:(NSData*)iv
{
	NSUInteger keyLength = [key length];
	if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256)
	{
		NSLog(@"key length is not 128/192/256-bits long");
        
		return nil;
	}
    
	char keyBytes[keyLength+1];
	bzero(keyBytes, sizeof(keyBytes));
	[key getCString:keyBytes maxLength:sizeof(keyBytes) encoding:NSUTF8StringEncoding];
    
	size_t numBytesEncrypted = 0;
	size_t encryptedLength = [self length] + kCCBlockSizeAES128;
	char* encryptedBytes = (char*)malloc(encryptedLength);
    bzero(encryptedBytes, encryptedLength);
	//(iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding)
	CCCryptorStatus result = CCCrypt(kCCEncrypt,
									 kCCAlgorithmAES128 ,
									 (iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding),	//default: CBC (when initial vector is supplied)
									 keyBytes,
									 keyLength,
									 [iv bytes],
									 [self bytes],
									 [self length],
									 encryptedBytes,
									 encryptedLength,
									 &numBytesEncrypted);
    
	if(result == kCCSuccess)
		return [NSData dataWithBytesNoCopy:encryptedBytes length:numBytesEncrypted];
    
	free(encryptedBytes);
	return nil;
}

- (NSData *)AES128Operation:(CCOperation)operation key:(NSString *)key iv:(NSData *)iv
{
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          [iv bytes],
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
    }
    free(buffer);
    return nil;
}

- (NSData*) aesDecryptWithKey:(NSString *)key initialVector:(NSData*)iv
{
	NSUInteger keyLength = [key length];
	if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256)
	{
		NSLog(@"key length is not 128/192/256-bits long");
		return nil;
	}
    
	char keyBytes[keyLength+1];
    memset(keyBytes, 0, sizeof(keyBytes));
	[key getCString:keyBytes maxLength:sizeof(keyBytes) encoding:NSUTF8StringEncoding];
    
	size_t numBytesDecrypted = 0;
	size_t decryptedLength = [self length] + kCCBlockSizeAES128;
	char* decryptedBytes = (char*)malloc(decryptedLength);
    memset(decryptedBytes, 0, sizeof(decryptedLength));
	CCCryptorStatus result = CCCrypt(kCCDecrypt,
									 kCCAlgorithmAES128 ,
									 (iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding), keyBytes,
									 kCCKeySizeAES128,
									 [iv bytes],
									 [self bytes],
									 [self length],
									 decryptedBytes,
									 decryptedLength,
									 &numBytesDecrypted);
    
	if(result == kCCSuccess)
    {
		return [NSData dataWithBytesNoCopy:decryptedBytes length:numBytesDecrypted];
    }
	NSLog(@"decrypt fail");
	free(decryptedBytes);
	return nil;
}

// 20110825. 将NSData转化为php十六进制表示形式.
- (NSString*) stringWithHexBytes
{
    NSMutableString *stringBuffer = [NSMutableString
                                     stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = (unsigned char *) [self bytes];
	int i;
	
	for (i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02lX", (unsigned long)dataBuffer[i]];
	
	return [stringBuffer copy];
}
- (NSData *) dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key
					initializationVector: (id) iv
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
	
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
	
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];// data or nil
	
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
	
	status = CCCryptorCreate( kCCEncrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
	
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
	
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
	
	CCCryptorRelease( cryptor );
	
	return ( result );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
								   error: (CCCryptorStatus *) error
{
	return ( [self decryptedDataUsingAlgorithm: algorithm
										   key: key
						  initializationVector: nil
									   options: 0
										 error: error] );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
                                 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
    return ( [self decryptedDataUsingAlgorithm: algorithm
										   key: key
						  initializationVector: nil
									   options: options
										 error: error] );
}

- (NSData *) decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
									 key: (id) key		// data or string
					initializationVector: (id) iv		// data or string
								 options: (CCOptions) options
								   error: (CCCryptorStatus *) error
{
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus status = kCCSuccess;
	
	NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
	
	NSMutableData * keyData, * ivData;
	if ( [key isKindOfClass: [NSData class]] )
		keyData = (NSMutableData *) [key mutableCopy];
	else
		keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	
	if ( [iv isKindOfClass: [NSString class]] )
		ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
	else
		ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
	
	// ensure correct lengths for key and iv data, based on algorithms
	FixKeyLengths( algorithm, keyData, ivData );
	
	status = CCCryptorCreate( kCCDecrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
	
	if ( status != kCCSuccess )
	{
		if ( error != NULL )
			*error = status;
		return ( nil );
	}
	
	NSData * result = [self _runCryptor: cryptor result: &status];
	if ( (result == nil) && (error != NULL) )
		*error = status;
	
	CCCryptorRelease( cryptor );
	
	return ( result );
}

@end

@implementation NSData (CommonHMAC)

- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm
{
	return ( [self HMACWithAlgorithm: algorithm key: nil] );
}

- (NSData *) HMACWithAlgorithm: (CCHmacAlgorithm) algorithm key: (id) key
{
	NSParameterAssert(key == nil || [key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
	
	NSData * keyData = nil;
	if ( [key isKindOfClass: [NSString class]] )
		keyData = [key dataUsingEncoding: NSUTF8StringEncoding];
	else
		keyData = (NSData *) key;
	
	// this could be either CC_SHA1_DIGEST_LENGTH or CC_MD5_DIGEST_LENGTH. SHA1 is larger.
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac( algorithm, [keyData bytes], [keyData length], [self bytes], [self length], buf );
	
	return ( [NSData dataWithBytes: buf length: (algorithm == kCCHmacAlgMD5 ? CC_MD5_DIGEST_LENGTH : CC_SHA1_DIGEST_LENGTH)] );
}

@end

@implementation NSData (DDData)

- (NSData *)gzipInflate
{
    if ([self length] == 0) return self;
    
    NSUInteger full_length = [self length];
    NSUInteger half_length = [self length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[self bytes];
    strm.avail_in = (uInt)[self length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

- (NSData *)gzipDeflate
{
    if ([self length] == 0) return self;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[self bytes];
    strm.avail_in = (uInt)[self length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);  
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

@end

@implementation NSData (Both)

- (NSData *)decryptAndDcompress:(NSData *)data
{
    // 解密
    NSString *password = kCommonCryptoPassword;// 加解密密码一致
    NSData *initialVector = [password dataUsingEncoding:NSUTF8StringEncoding];
    data = [data aesDecryptWithKey:password initialVector:initialVector];
    
    // 解压
    data = [data gzipInflate];
    
    return data;
}

- (NSData *)compressAndEncrypt:(NSData *)data {// 加解密密码一致
    // 压缩 --------------------------------------------------
    if ([self length] == 0) return self;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[self bytes];
    strm.avail_in = (uInt)[self length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    
    // 加密 --------------------------------------------------
    NSString *key = kCommonCryptoPassword;// 加解密密码一致
    NSData *iv = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger keyLength = [key length];
    if(keyLength != kCCKeySizeAES128 && keyLength != kCCKeySizeAES192 && keyLength != kCCKeySizeAES256)
    {
        NSLog(@"key length is not 128/192/256-bits long");
        
        return nil;
    }
    
    char keyBytes[keyLength+1];
    bzero(keyBytes, sizeof(keyBytes));
    [key getCString:keyBytes maxLength:sizeof(keyBytes) encoding:NSUTF8StringEncoding];
    
    size_t numBytesEncrypted = 0;
    size_t encryptedLength = [compressed length] + kCCBlockSizeAES128;
    char* encryptedBytes = (char*)malloc(encryptedLength);
    bzero(encryptedBytes, encryptedLength);
    //(iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding)
    CCCryptorStatus result = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128 ,
                                     (iv == nil ? kCCOptionECBMode | kCCOptionPKCS7Padding : kCCOptionPKCS7Padding),	//default: CBC (when initial vector is supplied)
                                     keyBytes,
                                     keyLength,
                                     [iv bytes],
                                     [compressed bytes],
                                     [compressed length],
                                     encryptedBytes,
                                     encryptedLength,
                                     &numBytesEncrypted);
    
    if(result == kCCSuccess)
        return [NSData dataWithBytesNoCopy:encryptedBytes length:numBytesEncrypted];
    
    free(encryptedBytes);
    return nil;
}

- (NSData *)decrypt:(NSData *)data
{
    NSString *password = kCommonCryptoPassword;// 加解密密码一致
    NSData *initialVector = [password dataUsingEncoding:NSUTF8StringEncoding];
    data = [data aesDecryptWithKey:password initialVector:initialVector];
    
    return data;
}

- (NSData *)encrypt:(NSData *)data {// 加解密密码一致
    NSString *password = kCommonCryptoPassword;// 加解密密码一致
    NSData *iv = [password dataUsingEncoding:NSUTF8StringEncoding];
    
    data = [data aesEncryptWithKey:password initialVector:iv];
    
    return data;
}

@end
