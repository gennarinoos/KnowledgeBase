//
//  Test.m
//  
//
//  Created by Gennaro Frazzingaro on 7/10/21.
//

#import <XCTest/XCTest.h>
#import "librdf_custom_storage_bridge.h"

static const char *kCKSparqlLanguageIdentifier = "sparql";

@interface CRDFStorageGenericTest : XCTestCase

@end

@implementation CRDFStorageGenericTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSMutableArray *results = [NSMutableArray new];
    NSString *queryString = @"SELECT";
    
    librdf_world *world = librdf_new_world();
    librdf_world_open(world);
    
    librdf_uri *base_uri = librdf_new_uri(world, (const unsigned char *)".");
    
    if (NULL == base_uri) {
        librdf_free_world(world);
    }
    
    librdf_storage_module_register_factory(world);
    librdf_query *query = librdf_new_query(world,
                                           kCKSparqlLanguageIdentifier,
                                           0,
                                           (unsigned char *)[queryString UTF8String],
                                           base_uri);
    
    if (NULL == query) {
        librdf_free_uri(base_uri);
        librdf_free_world(world);
        
        return;
    }
    
    librdf_storage *storage = librdf_new_storage(world,
                                                 kDefaultCustomStorageIdentifier,
                                                 "Blah",
                                                 "contexts='yes'");
    
    if (NULL == storage) {
        librdf_free_query(query);
        librdf_free_uri(base_uri);
        librdf_free_world(world);
        
        return;
    }
    
    librdf_model *model = librdf_new_model(world, storage, "contexts='yes'");
    
    if (NULL == model) {
        librdf_free_storage(storage);
        librdf_free_query(query);
        librdf_free_uri(base_uri);
        librdf_free_world(world);

        return;
    }
    
    librdf_query_results *rdf_results = librdf_query_execute(query, model);
    NSDictionary *resultsDictionary = librdf_query_results_get_nsdictionary_all_bindings(rdf_results);
    while (resultsDictionary) {
        [results addObject:resultsDictionary];
        resultsDictionary = librdf_query_results_get_nsdictionary_all_bindings(rdf_results);
    }
    
    librdf_free_query_results(rdf_results);
    librdf_free_storage(storage);
    librdf_free_model(model);
    librdf_free_query(query);
    librdf_free_uri(base_uri);
    librdf_free_world(world);
    
    return results;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
