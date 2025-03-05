//
//  NSURLConnection+FoundationCompletions.m
//  FrothKit
//
//  Created by Allan Phillips on 19/11/09.
//
//  Copyright (c) 2009 Thinking Code Software Inc. http://www.thinkingcode.ca
//
//	Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:

//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.

//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.

#import "NSURLConnection+FoundationCompletions.h"

#include "curl.h"
#include "easy.h"

struct MemoryStruct {
	char *memory;
	size_t size;
};

static void *myrealloc(void *ptr, size_t size);

static void *myrealloc(void *ptr, size_t size)
{
	/* There might be a realloc() out there that doesn't like reallocing
     NULL pointers, so we take care of it here */ 
	if(ptr)
		return realloc(ptr, size);
	else
		return malloc(size);
}

static size_t
WriteMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data)
{
	size_t realsize = size * nmemb;
	struct MemoryStruct *mem = (struct MemoryStruct *)data;
	
	mem->memory = myrealloc(mem->memory, mem->size + realsize + 1);
	if (mem->memory) {
		memcpy(&(mem->memory[mem->size]), ptr, realsize);
		mem->size += realsize;
		mem->memory[mem->size] = 0;
	}
	return realsize;
}

/*static size_t
ReadMemoryCallback(void* ptr, size_t size, size_t nitems, void* data) {

}*/

//Simple wrapper as cocotron does not implement this, this should fully support all of NSMutableURLResponse
@interface NSURLResponse_Froth : NSHTTPURLResponse {
	int m_status;
}

@end

@implementation NSURLResponse_Froth

- (id)initWithStatusCode:(NSInteger)code {
	if(self = [super init]) {
		m_status = code;
	}
	return self;
}

- (NSInteger)statusCode {
	return m_status;
}

@end


@implementation NSURLConnection (FoundationCompletions)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)responsep error:(NSError **)errorp {
	//NSLog(@"Starting!");
	struct MemoryStruct response;
	response.memory = NULL;
	response.size = 0;
	//NSLog(@"called");
	struct curl_slist *slist = NULL;
	
	CURL* chandle = curl_easy_init();
	curl_easy_setopt(chandle, CURLOPT_URL, [[[request URL] absoluteString] UTF8String]);
	//NSLog(@"itadakimasu = %@", [[request URL] absoluteString]);
	curl_easy_setopt(chandle, CURLOPT_FOLLOWLOCATION, 1);
	curl_easy_setopt(chandle, CURLOPT_SSL_VERIFYPEER, 0);
    curl_easy_setopt(chandle, CURLOPT_NOSIGNAL, 1);
    
	FILE * uf = NULL;	//FILE uploaded if any
	
	NSString* method = [request HTTPMethod];
	if([method isEqualToString:@"GET"]) {
		curl_easy_setopt(chandle, CURLOPT_HTTPGET, 1);
	} else if([method isEqualToString:@"POST"]) {
		NSData* body = [request HTTPBody];
		curl_easy_setopt(chandle, CURLOPT_POSTFIELDS, [body bytes]);
		curl_easy_setopt(chandle, CURLOPT_POSTFIELDSIZE, [body length]);
	} else if([method isEqualToString:@"PUT"]) {
		curl_easy_setopt(chandle, CURLOPT_PUT, 1L);
		NSData* body = [request HTTPBody];
		int dataLength = [body length];
		
		curl_easy_setopt(chandle, CURLOPT_UPLOAD, 1L);
		curl_easy_setopt(chandle, CURLOPT_INFILESIZE, dataLength);	//This also sets the 'Content-Length' header...*/

		if(dataLength>0) {
			/* Hacky, and incomplete with no error checking! */
			NSString* fname = [NSString stringWithFormat:@"/tmp/%f.fputdata", [[NSDate date] timeIntervalSinceReferenceDate]];
			[body writeToFile:fname atomically:YES];
			uf = fopen([fname UTF8String], "r");
			//curl_easy_setopt(easyhandle, CURLOPT_READFUNCTION, read_function
			curl_easy_setopt(chandle, CURLOPT_READDATA, uf);		
		
		}
	} else if([method isEqualToString:@"DELETE"]) {
		 curl_easy_setopt(chandle, CURLOPT_CUSTOMREQUEST, "DELETE");
	}
	
	//TODO: Create a read function and pointer for reading post/put data
	NSDictionary* headers = [request allHTTPHeaderFields];
	NSArray* hkeys = [headers allKeys];
	if([hkeys count]) {
		for(NSString*headerKey in hkeys) {
			NSString*hvalue = [headers valueForKey:headerKey];
			if((NSNull*)hvalue != [NSNull null]) {
				slist = curl_slist_append(slist, [[NSString stringWithFormat:@"%@: %@", headerKey, hvalue] UTF8String]);
			} else {
				slist = curl_slist_append(slist, [[NSString stringWithFormat:@"%@:", headerKey] UTF8String]);
			}
			//NSLog(@"SetReq - Header [%@:%@]", headerKey, hvalue);
		}
		curl_easy_setopt(chandle, CURLOPT_HTTPHEADER, slist);
	}
		
	curl_easy_setopt(chandle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
	curl_easy_setopt(chandle, CURLOPT_WRITEDATA, (void *)&response);
	//curl_easy_setopt(chandle, CURLOPT_VERBOSE, 1);
	int ret = curl_easy_perform(chandle);
	if(ret == 0) { //Success
		curl_slist_free_all(slist);
		int code;
		curl_easy_getinfo(chandle, CURLINFO_RESPONSE_CODE, &code);
		//NSLog(@"response code:%i",code);
		
		//Simple response based on status code.
		///--- Does not work...
		//*responsep = [[NSURLResponse_Froth alloc] initWithStatusCode:code];
		
		//TODO add header response as well...
				
		if(uf) {
			//NSLog(@"closing file descrp");
			fclose(uf);
		}
		
		curl_easy_cleanup(chandle);
		
		NSData* data = [NSData dataWithBytes:(void*)response.memory length:response.size];
		// 200 is successful
		if (code == 200) {
			//NSLog(@"returned data");
			return data;
		} else {
			return data;
		}
	} else {
		//NSLog(@"--- NSURLConnection+LibCurl Wrapper Error --- ret = %i", ret);
		curl_slist_free_all(slist);
		curl_easy_cleanup(chandle);
		if(uf) {
			fclose(uf);
		}
		*errorp = [NSError errorWithDomain:@"FrothNSURLConnectionDomain" code:9231 userInfo:nil];
		return NULL;
	}
}

@end
