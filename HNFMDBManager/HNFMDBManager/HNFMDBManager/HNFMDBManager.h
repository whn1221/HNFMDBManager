//
//  HNFMDBManager.h
//  test
//
//  Created by xydtech on 16/12/22.
//  Copyright © 2016年 xiaoyudiantech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HNFMDBManager : NSObject

/** 项目中是否只需要一个数据库 */
@property(nonatomic,assign,getter=isSingleDB)BOOL singleDB;

#pragma mark --  当项目中只需要一个数据库的时候
/** 创建单例 */
+ (instancetype)shareManager;
/** 配合单例使用,创建项目中唯一的数据库 */
- (void)creatSingleDBName:(NSString *)singleDBName;

#pragma mark --  当项目中只需要一个数据库的时候初始化
- (instancetype)initWithDBName:(NSString *)dbName;

#pragma mark -- 创表
/** 根据类名创建表，如果有则跳过，没有才创建 */
- (BOOL)hn_createTable:(Class)modelClass;

#pragma mark -- 插入

/** 插入单个模型或者模型数组(也可以直接是数据,会自动识别是单个模型还是模型数组,即此方法功能包括 hn_insertModelArr 方法功能) */
- (BOOL)hn_insertModel:(id)model;
/** 插入模型数组 */
- (BOOL)hn_insertModelArr:(NSArray *)modelArr;

#pragma mark -- 查询
/** 查询指定表是否存在，执行完毕后自动关闭数据库 */
- (BOOL)hn_isExitTable:(Class)modelClass;
/** 查找指定表中指定DBID的模型，执行完毕后自动关闭数据库 */
- (id)hn_searchModel:(Class)modelClass byID:(NSString *)hnDBID;
/** 查找指定表中模型数组（所有的），执行完毕后自动关闭数据库 */
- (NSArray *)hn_searchModelArr:(Class)modelClass;


#pragma mark -- 修改

/** 修改指定DBID的模型，执行完毕后自动关闭数据库 */
- (BOOL)hn_modifyModel:(id)model byID:(NSString *)hnDBID;


#pragma mark -- 删除
/** 删除指定表，执行完毕后自动关闭数据库 */
- (BOOL)hn_dropTable:(Class)modelClass;
/** 删除指定表格的所有数据，执行完毕后自动关闭数据库 */
- (BOOL)hn_deleteAllModel:(Class)modelClass;
/** 删除指定表中指定DBID的模型，执行完毕后自动关闭数据库 */
- (BOOL)hn_deleteModel:(Class)modelClass byId:(NSString *)hnDBID;

@end
