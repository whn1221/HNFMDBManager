//
//  ViewController.m
//  HNFMDBManager
//
//  Created by xydtech on 17/3/24.
//  Copyright © 2017年 xiaoyudiantech. All rights reserved.
//

#import "ViewController.h"
#import "TestModel.h"
#import "MJExtension.h"
#import "HNFMDBManager.h"

#define NSLog(...) NSLog(@"%s 第%d行 \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self testFMDB];
}


- (void)testFMDB
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *messagesPath = [bundle pathForResource:@"data" ofType:@"json"];
    NSData *messagesData = [NSData dataWithContentsOfFile:messagesPath];
    NSArray *messages;
    if (messagesData) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:messagesData options:NSJSONReadingAllowFragments error:nil];
        messages = dictionary[@"data"];
    }
    
    NSLog(@"%@", messages);
    
    //model里面必须有一个参数是hnDBID  ,是服务器返回数据中此model的唯一标示
    
    [TestModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"hnDBID" : @"id"
                 };
    }];
    
    NSArray * array = [TestModel mj_objectArrayWithKeyValuesArray:messages];
    
#pragma mark -- 项目中只需要创建一个数据库时候这种方法初始化,建议在APPdelegate中
    //    HNFMDBManager * dbManager = [HNFMDBManager shareManager];
    //    [dbManager setSingleDB:YES];
    //    //创建数据库
    //    [dbManager creatSingleDBName:@"ceshiDB.sqlite"];
    
#pragma mark -- 当项目中需要创建多个数据库时候,用一下方法,只用在需要使用的位置按照下面方法初始化即可,对已存在数据库操作时名字必须一致,建议使用宏定义
    //初始化第一张表格
    HNFMDBManager * dbManager = [[HNFMDBManager alloc] initWithDBName:@"NoSingleDBName.sqlite"];
    [dbManager setSingleDB:NO];
    
    
    HNFMDBManager * dbManager1 = [[HNFMDBManager alloc] initWithDBName:@"NoSingleDBName1.sqlite"];
    [dbManager1 setSingleDB:NO];
    
    
    
    //创建表格
    [dbManager hn_createTable:[TestModel class]];
    
    //创建表格
    [dbManager1 hn_createTable:[TestModel class]];
    
#pragma mark -- 插入操作
    //插入一条数据
    BOOL insertResult = [dbManager hn_insertModel:array[0]];
    if (insertResult) {
        NSLog(@"插入一条成功");
    }else{
        NSLog(@"插入一条失败");
    }
    
    //插入多条数据
    BOOL insertArrayResult = [dbManager hn_insertModelArr:array];
    if (insertArrayResult) {
        NSLog(@"插入多条成功");
    }else{
        NSLog(@"插入多条失败");
    }
    
    //查询数据库中表格是否存在
    if ([dbManager hn_isExitTable:[TestModel class]]) {
        NSLog(@"在数据库中这个表已经存在");
    }
    
#pragma mark -- 查询操作
    //更具ID查询某一条数据
    TestModel * model = array[1];
    TestModel * searchResult = [dbManager hn_searchModel:[TestModel class] byID:model.hnDBID];
    if (searchResult) {
        NSLog(@"查询一条结果: \n %@", searchResult);
    }else{
        NSLog(@"查询的不存在");
    }
    
    //查询表格中所有数据
    NSArray * searchArrayResult = [dbManager hn_searchModelArr:[TestModel class]];
    if (searchArrayResult) {
        NSLog(@"查询多条结果: \n %@", searchArrayResult);
    }else{
        NSLog(@"查询多条失败");
    }
    
#pragma mark -- 修改操作
    //修改
    TestModel * modifymodel = array[2];
    NSLog(@"修改前结果: \n %@", modifymodel.title);
    modifymodel.title = @"修改title";
    
    BOOL modifyResult = [dbManager hn_modifyModel:modifymodel byID:modifymodel.hnDBID];
    if (modifyResult) {
        NSLog(@"修改后结果: \n %@", [dbManager hn_searchModel:[TestModel class] byID:model.hnDBID]);
    }else{
        NSLog(@"修改失败");
    }
    
#pragma mark -- 删除操作
    //删除指定数据
    TestModel * delemodel = array[3];
    NSLog(@"删除之前:%@", [dbManager hn_searchModelArr:[TestModel class]]);
    BOOL deleResult1 = [dbManager hn_deleteModel:[TestModel class] byId:delemodel.hnDBID];
    if (deleResult1) {
        NSLog(@"删除后后结果: \n %@", [dbManager hn_searchModel:[TestModel class] byID:model.hnDBID]);
    }else{
        NSLog(@"删除指定数据失败");
    }
    //删除表格中所有数控,当时表格还在数据库中
    BOOL deleResult2 = [dbManager hn_deleteAllModel:[TestModel class]];
    if (deleResult2) {
        NSLog(@"删除表格所有数据成功");
    }else{
        NSLog(@"删除整个表格所有数据失败");
    }
    //从数据库中把表格删除,操作后数据库中存在此表格了
    BOOL deleResult3 = [dbManager hn_dropTable:[TestModel class]];
    if (deleResult3) {
        NSLog(@"从数据库中删除表格成功");
    }else{
        NSLog(@"从数据库中删除表格失败");
    }
    
}



@end
