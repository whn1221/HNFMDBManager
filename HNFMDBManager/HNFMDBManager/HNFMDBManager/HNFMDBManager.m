//
//  HNFMDBManager.m
//  test
//
//  Created by xydtech on 16/12/22.
//  Copyright © 2016年 xiaoyudiantech. All rights reserved.
//

#import "HNFMDBManager.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#define kIsNull(exp) ((exp == nil || exp == NULL || ([exp isKindOfClass:[NSString class]] && [exp length] == 0))?1:0)

@interface HNFMDBManager()

@property (nonatomic,strong)FMDatabase *dataBase;


@property (nonatomic,strong)FMDatabase * singleDataBase;

@property (nonatomic,copy)NSString * dbName;
@property (nonatomic,strong)FMDatabase * noSingleDataBase;

@end

@implementation HNFMDBManager

+ (instancetype)shareManager{
    static HNFMDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)creatSingleDBName:(NSString *)singleDBName
{
    HNFMDBManager * manager = [HNFMDBManager shareManager];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *sqlFilePath = [path stringByAppendingPathComponent:singleDBName];
    NSLog(@"%@", sqlFilePath);
    // 通过路径创建数据库
    manager.singleDataBase = [FMDatabase databaseWithPath:sqlFilePath];
}

- (instancetype)initWithDBName:(NSString *)dbName {
    if (self = [super init]) {
        NSAssert(!kIsNull(dbName), @"数据库名称不能为空");
        self.dbName = dbName;
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *sqlFilePath = [path stringByAppendingPathComponent:dbName];
        NSLog(@"%@", sqlFilePath);
        self.noSingleDataBase = [FMDatabase databaseWithPath:sqlFilePath];
    }
    return self;
}

- (BOOL)hn_createTable:(Class)modelClass
{
    return [self hn_createTable:modelClass autoCloseDB:YES];
}


- (BOOL)hn_createTable:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        // 创表,判断是否已经存在
        if ([self isExitTable:modelClass autoCloseDB:NO]) {
            if (autoCloseDB) {
                [self.dataBase close];
            }
            return YES;
        }
        else{
            BOOL success = [self.dataBase executeUpdate:[self createTableSQL:modelClass]];
            // 关闭数据库
            if (autoCloseDB) {
                [self.dataBase close];
            }
            return success;
        }
    }
    else{
        return NO;
    }
}

/** 指定的表是否存在 */
- (BOOL)isExitTable:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    
    
    if ([self.dataBase open]){
        BOOL success = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",modelClass]];
        // 操作完毕是否需要关闭
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return success;
    }
    else{
        return NO;
    }
}


- (id)hn_searchModel:(Class)modelClass byID:(NSString *)hnDBID{
    return [self hn_searchModel:modelClass byID:hnDBID autoCloseDB:YES];
}

- (NSArray *)hn_searchModelArr:(Class)modelClass{
    if ([self.dataBase open]) {
        [self tableIsExit:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",modelClass]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        // 遍历结果集
        while ([rs next]) {
            
            // 创建对象
            id object = [[modelClass class] new];
            
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    }
                    else{
                        [object setValue:value forKey:key];
                    }
                }
                else{
                    [object setValue:value forKey:key];
                }
            }
            
            // 添加
            [modelArrM addObject:object];
        }
        [self.dataBase close];
        return modelArrM.copy;
    }
    else{
        return nil;
    }
}


- (BOOL)hn_modifyModel:(id)model byID:(NSString *)hnDBID{
    return [self hn_modifyModel:model byID:hnDBID autoCloseDB:YES];
}

- (BOOL)hn_dropTable:(Class)modelClass{
    if ([self.dataBase open]) {
        [self tableIsExit:modelClass];
        // 删除数据
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %@;",modelClass];
        BOOL success = [self.dataBase executeUpdate:sql];
        [self.dataBase close];
        return success;
    }
    else{
        return NO;
    }
}

- (BOOL)hn_deleteAllModel:(Class)modelClass{
    if ([self.dataBase open]) {
        [self tableIsExit:modelClass];
        // 删除数据
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@;",modelClass];
        BOOL success = [self.dataBase executeUpdate:sql];
        [self.dataBase close];
        return success;
    }
    else{
        return NO;
    }
}

- (BOOL)hn_deleteModel:(Class)modelClass byId:(NSString *)hnDBID{
    if ([self.dataBase open]) {
        [self tableIsExit:modelClass];
        // 删除数据
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE  hnDBID = '%@';",modelClass,hnDBID];
        BOOL success = [self.dataBase executeUpdate:sql];
        [self.dataBase close];
        return success;
    }
    else{
        return NO;
    }
}

- (BOOL)hn_isExitTable:(Class)modelClass{
    return [self isExitTable:modelClass autoCloseDB:YES];
}

- (BOOL)hn_insertModel:(id)model
{
    if ([model isKindOfClass:[NSArray class]] || [model isKindOfClass:[NSMutableArray class]]) {
        NSArray *modelArr = (NSArray *)model;
        return [self hn_insertModelArr:modelArr];
    }
    else{
        return [self hn_insertModel:model autoCloseDB:YES];
    }
}
- (BOOL)hn_insertModelArr:(NSArray *)modelArr{
    BOOL hnag = YES;
    for (id model in modelArr) {
        // 处理过程中不关闭数据库
        if (![self hn_insertModel:model autoCloseDB:NO]) {
            hnag = NO;
        }
    }
    // 处理完毕关闭数据库
    [self.dataBase close];
    // 全部插入成功才返回YES
    return hnag;
}

- (BOOL)hn_insertModel:(id)model autoCloseDB:(BOOL)autoCloseDB{
    NSAssert(![model isKindOfClass:[UIResponder class]], @"必须保证模型是NSObject或者NSObject的子类,同时不响应事件");
    if ([self.dataBase open]) {
        // 此时有三步操作，第一步处理完不关闭数据库
        if (![self isExitTable:[model class] autoCloseDB:NO]) {
            // 第二步处理完不关闭数据库
            BOOL success = [self hn_createTable:[model class] autoCloseDB:NO];
            if (success) {
                NSString *hn_dbid = [model valueForKey:@"hnDBID"];
                id judgeModle = [self hn_searchModel:[model class] byID:hn_dbid autoCloseDB:NO];
                
                if ([[judgeModle valueForKey:@"hnDBID"] isEqualToString:hn_dbid]) {
                    BOOL updataSuccess = [self hn_modifyModel:model byID:hn_dbid autoCloseDB:NO];
                    if (autoCloseDB) {
                        [self.dataBase close];
                    }
                    return updataSuccess;
                }
                else{
                    BOOL insertSuccess = [self.dataBase executeUpdate:[self createInsertSQL:model]];
                    // 最后一步操作完毕，询问是否需要关闭
                    if (autoCloseDB) {
                        [self.dataBase close];
                    }
                    return insertSuccess;
                }
                
            }
            else {
                // 第二步操作失败，询问是否需要关闭,可能是创表失败，或者是已经有表
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return NO;
            }
        }
        // 已经创建有对应的表，直接插入
        else{
            NSString *hn_dbid = [model valueForKey:@"hnDBID"];
            id judgeModle = [self hn_searchModel:[model class] byID:hn_dbid autoCloseDB:NO];
            
            if ([[judgeModle valueForKey:@"hnDBID"] isEqualToString:hn_dbid]) {
                BOOL updataSuccess = [self hn_modifyModel:model byID:hn_dbid autoCloseDB:NO];
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return updataSuccess;
            }
            else{
                BOOL insertSuccess = [self.dataBase executeUpdate:[self createInsertSQL:model]];
                // 最后一步操作完毕，询问是否需要关闭
                if (autoCloseDB) {
                    [self.dataBase close];
                }
                return insertSuccess;
            }
        }
    }
    else{
        return NO;
    }
}

#pragma mark -- private method
/** 创建表的SQL语句 */
- (NSString *)createTableSQL:(Class)modelClass{
    NSMutableString *sqlPropertyM = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT ",modelClass];
    
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(modelClass, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        //去除参数名第一字符:"_"
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        [sqlPropertyM appendFormat:@", %@",key];
    }
    [sqlPropertyM appendString:@")"];
    
    return sqlPropertyM;
}

/** 创建插入表的SQL语句 */
- (NSString *)createInsertSQL:(id)model{
    NSMutableString *sqlValueM = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ (",[model class]];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if (i == 0) {
            [sqlValueM appendString:key];
        }
        else{
            [sqlValueM appendFormat:@", %@",key];
        }
    }
    [sqlValueM appendString:@") VALUES ("];
    
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id value = [model valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [NSString stringWithFormat:@"%@",value];
        }
        if (i == 0) {
            // sql 语句中字符串需要单引号或者双引号括起来
            [sqlValueM appendFormat:@"%@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
        else{
            [sqlValueM appendFormat:@", %@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
    }
    [sqlValueM appendString:@");"];
    
    return sqlValueM;
}


- (id)hn_searchModel:(Class)modelClass byID:(NSString *)hnDBID autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        [self tableIsExit:modelClass];
        // 查询数据
        FMResultSet *rs = [self.dataBase executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE hnDBID = '%@';",modelClass,hnDBID]];
        // 创建对象
        id object = [[modelClass class] new];
        // 遍历结果集
        while ([rs next]) {
            
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    }
                    else{
                        [object setValue:value forKey:key];
                    }
                }
                else{
                    [object setValue:value forKey:key];
                }
            }
        }
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return object;
    }
    else{
        return nil;
    }
}

- (BOOL)hn_modifyModel:(id)model byID:(NSString *)hnDBID autoCloseDB:(BOOL)autoCloseDB{
    if ([self.dataBase open]) {
        [self tableIsExit:[model class]];
        NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[model class]];
        unsigned int outCount;
        Ivar * ivars = class_copyIvarList([model class], &outCount);
        for (int i = 0; i < outCount; i ++) {
            Ivar ivar = ivars[i];
            NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
            if([[key substringToIndex:1] isEqualToString:@"_"]){
                key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            id value = [model valueForKey:key];
            if (i == 0) {
                [sql appendFormat:@"%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            }
            else{
                [sql appendFormat:@",%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            }
        }
        
        [sql appendFormat:@" WHERE hnDBID = '%@';",hnDBID];
        BOOL success = [self.dataBase executeUpdate:sql];
        if (autoCloseDB) {
            [self.dataBase close];
        }
        return success;
    }
    else{
        return NO;
    }
    
}

- (void)tableIsExit:(Class)modelClass
{
    NSString *classNameTip = [NSString stringWithFormat:@"%@ 表不存在，请先创建",modelClass];
    NSAssert([self isExitTable:modelClass autoCloseDB:NO], classNameTip);
}

- (FMDatabase *)dataBase
{
    if (self.isSingleDB) {
        return self.singleDataBase;
    }else{
        NSAssert(!kIsNull(self.dbName), @"此数据库不存在,请先创建");
        return self.noSingleDataBase;
    }
}


@end
