//
//  YYClassInfo.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYClassInfo.h"
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

/**
 *  将类似 T@"Car",&,N,V_car 这样的数据类型的type encodings字符串，先分割成如下的多个键值对
 
 //每一项都是一个 objc_property_attribute_t 结构体实例
 name = T, value = @"User" >>> T@"User" >>> Ivar的类型是User
 name = &, value =           >>> & >>> retain
 name = N, value =           >>> N >>> nonatomic
 name = V, value = _user     >>> V_user >>> Ivar的名字是 _user
 
 //一个属性编码特征值项的类型定义
 typedef struct {
    const char *name;           //< The name of the attribute
    const char *value;          //< The value of the attribute (usually empty)
 } objc_property_attribute_t;

主要有几种类型的编码:

- 类型一、变量

````````````````````````````````````
const char *type1 = @encode(Person);
const char *type2 = @encode(int);
const char *type3 = @encode(BOOL);

type1 = @"{Person=#}"
type2 = @"i"
type3 = @"B"
````````````````````````````````````

- 类型二、属性

````````````````````````````````````
@property Car *car;

以T开头，如: T@"Car",&,N,V_car
````````````````````````````````````

- 类型三、方法，其又分为如下三种类型的编码
    - 方法本身的编码
    const char *method_getTypeEncoding(Method m)

    - 方法参数列表中，所有类型的编码
    char *method_copyArgumentType(Method m, unsigned int index)

    - 方法返回值类型的编码
    char *method_copyReturnType(Method m)
*/

/**
 *  接收一个属性编码特征值键值对，然后解析成对应的编码枚举值
 *  如下方法主要对
 *
 *  @param typeEncoding 一个objc_property_attribute_t实例->value 所指的字符串值
 *
 *  @return XZHEncodingType枚举值
 */

YYEncodingType YYEncodingGetType(const char *typeEncoding) {
    
    //1. 转换const限定符
    char *type = (char *)typeEncoding;
    
    //2. 编码字符串为NULL，返回未知类型
    if (!type) return YYEncodingTypeUnknown;
    size_t len = strlen(type);
    
    //3. 编码字符串的长度不能为零，否则返回未知类型
    if (len == 0) return YYEncodingTypeUnknown;
    
    //4. 方法的修饰类型
    YYEncodingType qualifier = 0;
    bool prefix = true;
    
    //可能多个编码字符（多个方法修饰）
    while (prefix) {
        
        //当前编码字符的type encodings意义
        switch (*type) {
                
            //const 修饰的方法
            case 'r': {
                
                //加法运算,加上一个枚举值
                qualifier |= YYEncodingTypeQualifierConst;
                
                //字符指针下移，指向下一个字符
                type++;
            } break;
                
            //in 修饰的方法
            case 'n': {
                qualifier |= YYEncodingTypeQualifierIn;
                type++;
            } break;
                
            //inout 修饰的方法
            case 'N': {
                qualifier |= YYEncodingTypeQualifierInout;
                type++;
            } break;
                
            //out 修饰的方法
            case 'o': {
                qualifier |= YYEncodingTypeQualifierOut;
                type++;
            } break;
                
            //bycopy 修饰的方法
            case 'O': {
                qualifier |= YYEncodingTypeQualifierBycopy;
                type++;
            } break;
                
            //byref 修饰的方法
            case 'R': {
                qualifier |= YYEncodingTypeQualifierByref;
                type++;
            } break;
                
            //oneway 修饰的方法
            case 'V': {
                qualifier |= YYEncodingTypeQualifierOneway;
                type++;
            } break;
            default: {
                //当前字符不再匹配 method encodings字符
                prefix = false;
            }
                break;
        }
    }

    //5. 判读还有无后续字符
    len = strlen(type);
    if (len == 0) return YYEncodingTypeUnknown | qualifier;

    //6. 数据类型
    //直接返回下面匹配的一种类型枚举值
    switch (*type) {
        //6.1 返回 基本数据类型
        case 'v': return YYEncodingTypeVoid | qualifier;
        case 'B': return YYEncodingTypeBool | qualifier;
        case 'c': return YYEncodingTypeInt8 | qualifier;
        case 'C': return YYEncodingTypeUInt8 | qualifier;
        case 's': return YYEncodingTypeInt16 | qualifier;
        case 'S': return YYEncodingTypeUInt16 | qualifier;
        case 'i': return YYEncodingTypeInt32 | qualifier;
        case 'I': return YYEncodingTypeUInt32 | qualifier;
        case 'l': return YYEncodingTypeInt32 | qualifier;
        case 'L': return YYEncodingTypeUInt32 | qualifier;
        case 'q': return YYEncodingTypeInt64 | qualifier;
        case 'Q': return YYEncodingTypeUInt64 | qualifier;
        case 'f': return YYEncodingTypeFloat | qualifier;
        case 'd': return YYEncodingTypeDouble | qualifier;
        case 'D': return YYEncodingTypeLongDouble | qualifier;
            
        //6.2 返回 复杂数据类型
        case '#': return YYEncodingTypeClass | qualifier;
        case ':': return YYEncodingTypeSEL | qualifier;
        case '*': return YYEncodingTypeCString | qualifier;
        case '^': return YYEncodingTypePointer | qualifier;
        case '[': return YYEncodingTypeCArray | qualifier;
        case '(': return YYEncodingTypeUnion | qualifier;
        case '{': return YYEncodingTypeStruct | qualifier;
            
        //6.3 返回 Block类型 或 自定义NSObject类型
        case '@': {
            if (len == 2 && *(type + 1) == '?'){
                //block类型 '@?'
                return YYEncodingTypeBlock | qualifier;
            }else{
                //NSObject类，包含两种：
                //1. Foundation类：@NSString，@NSArray，...
                //2. 自定义继承自NSObject的子类实体类
                return YYEncodingTypeObject | qualifier;
            }
        }
        default:{
            //不符合指定类型
            return YYEncodingTypeUnknown | qualifier;
        }
    }
}


@implementation YYClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    //1. 传入的Ivar不能为空
    if (!ivar) return nil;
    
    //2. 使用Ivar创建一个模型类对象
    self = [super init];
    
    //3. 保存Ivar的所有info
    _ivar = ivar;
    const char *name = ivar_getName(ivar);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    _offset = ivar_getOffset(ivar);
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        _type = YYEncodingGetType(typeEncoding);
    }
    return self;
}

@end

@implementation YYClassMethodInfo

- (instancetype)initWithMethod:(Method)method {
    //1. 传入的mehtod不能为空
    if (!method) return nil;
    
    //2. 创建MethodInfo的类对象模型
    self = [super init];
    _method = method;
    
    //3. 获取method的SEL
    _sel = method_getName(method);
    
    //4. 获取method的方法IMP指针
    _imp = method_getImplementation(method);
    
    //5. 获取method的方法名称字符串
    const char *name = sel_getName(_sel);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    //6. 获取方法的编码
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    
    //7. 获取方法返回值的编码
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        
        //注意: 只要带 copy、retain、alloc之类的系统方法得到的，不使用时必须使用release()或free()
        free(returnType);
    }
    
    //8. 获取方法参数的编码
    //方法的总参数个数
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
        
        //使用数组保存每一个参数类型的编码
        NSMutableArray *argumentTypes = [NSMutableArray new];
        for (unsigned int i = 0; i < argumentCount; i++) {
            
            //获取方法的每一个参数的编码
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            
            //使用数组保存所有的参数类型编码
            [argumentTypes addObject:type ? type : @""];
            
            //释放系统Api创建的内存
            if (argumentType) free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    
    /** 
     只要带 copy、retain、alloc之类的系统方法得到的内存，不使用时必须使用release()或free()释放掉
     
     -write by khzliu */
    
    return self;
}

@end

@implementation YYClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property {
    //1. 属性不能为空
    if (!property) return nil;
    self = [self init];
    _property = property;
    
    //2. 获取属性的字符串名称
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    //3. 获取每一个属性的 @encode()编码字符串
    /*
     T@"NSString",C,N,V_name分割成如下子项:
     
     name = T, value = @"User"
     name = &, value =
     name = N, value =
     name = V, value = _user
     */
    
    //最终的类型枚举值
    YYEncodingType type = 0;
    
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    
    //3.2 遍历 每一个 特征值对(name:value)
    for (unsigned int i = 0; i < attrCount; i++) {
        
        //3.2.1 当前属性
        //attr.name = "T"
        //attr.value = "@\"User\""
        switch (attrs[i].name[0]) {
                
                //T@Uer、属性变量的类型编码
            case 'T': { // Type encoding//TB、Tq、Tf、T@User
                
                //attr.value: 如: @"User"
                if (attrs[i].value) {
                    
                    // 保存 属性变量类型 的编码字符串
                    _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                    
                    //保存 属性变量类型 编码对应的枚举值
                    //注意，不使用 | 加运算
                    //因为属性的编码字符串是以 `T`字符 开头
                    type = YYEncodingGetType(attrs[i].value);
                    
                    //如果属性变量类型是实体类，取出其实体类Class，如: User
                    if (type & YYEncodingTypeObject) {
                        
                        //特征值类型为自定义对象，如: "@\"User\"" --> @，\"，U，s，e，r，\"
                        size_t len = strlen(attrs[i].value);
                        if (len > 3) {//@\"U...
                            char name[len - 2];//创建一个len==5的新字符数组
                            name[len - 3] = '\0';//将name数组最后一个位置赋值结束符\0
                            memcpy(name, attrs[i].value + 2, len - 3);//复制User到name字符数组
                            _cls = objc_getClass(name);//保存属性变量的Class
                        }
                    }
                }
            } break;
            
            //V_user、属性变量的名字
            case 'V': { // Instance variable
                if (attrs[i].value) {
                    _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
                
            //属性使用readonly
            case 'R': {
                type |= YYEncodingTypePropertyReadonly;
            } break;
                
            //属性使用copy
            case 'C': {
                type |= YYEncodingTypePropertyCopy;
            } break;
                
            //属性使用retain
            case '&': {
                type |= YYEncodingTypePropertyRetain;
            } break;
            
            //属性使用nonatiomic
            case 'N': {
                type |= YYEncodingTypePropertyNonatomic;
            } break;
                
            //属性使用dynamic
            case 'D': {
                type |= YYEncodingTypePropertyDynamic;
            } break;
            
            //属性使用weak
            case 'W': {
                type |= YYEncodingTypePropertyWeak;
            } break;
                
            //属性使用getter
            case 'G': {
                type |= YYEncodingTypePropertyCustomGetter;
                if (attrs[i].value) {
                    _getter = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
                
            //属性使用setter
            case 'S': {
                type |= YYEncodingTypePropertyCustomSetter;
                if (attrs[i].value) {
                    _setter = [NSString stringWithUTF8String:attrs[i].value];
                }
            } break;
            default: break;
        }
    }
    
    //3. 释放系统对象
    if (attrs) {
        free(attrs);
        attrs = NULL;
    }
    
    _type = type;
    if (_name.length) {
        if (!_getter) {
            _getter = _name;
        }
        if (!_setter) {
            _setter = [NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]];
        }
    }
    return self;
}

@end

@implementation YYClassInfo {
    BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls {
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    _superCls = class_getSuperclass(cls);
    _isMeta = class_isMetaClass(cls);
    if (!_isMeta) {
        _metaCls = objc_getMetaClass(class_getName(cls));
    }
    _name = NSStringFromClass(cls);
    [self _update];

    _superClassInfo = [self.class classInfoWithClass:_superCls];
    return self;
}

- (void)_update {
    _ivarInfos = nil;
    _methodInfos = nil;
    _propertyInfos = nil;
    
    Class cls = self.cls;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        NSMutableDictionary *methodInfos = [NSMutableDictionary new];
        _methodInfos = methodInfos;
        for (unsigned int i = 0; i < methodCount; i++) {
            YYClassMethodInfo *info = [[YYClassMethodInfo alloc] initWithMethod:methods[i]];
            if (info.name) methodInfos[info.name] = info;
        }
        free(methods);
    }
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties) {
        NSMutableDictionary *propertyInfos = [NSMutableDictionary new];
        _propertyInfos = propertyInfos;
        for (unsigned int i = 0; i < propertyCount; i++) {
            YYClassPropertyInfo *info = [[YYClassPropertyInfo alloc] initWithProperty:properties[i]];
            if (info.name) propertyInfos[info.name] = info;
        }
        free(properties);
    }
    
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars) {
        NSMutableDictionary *ivarInfos = [NSMutableDictionary new];
        _ivarInfos = ivarInfos;
        for (unsigned int i = 0; i < ivarCount; i++) {
            YYClassIvarInfo *info = [[YYClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (info.name) ivarInfos[info.name] = info;
        }
        free(ivars);
    }
    _needUpdate = NO;
}

- (void)setNeedUpdate {
    _needUpdate = YES;
}

+ (instancetype)classInfoWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef classCache;
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    static OSSpinLock lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = OS_SPINLOCK_INIT;
    });
    OSSpinLockLock(&lock);
    YYClassInfo *info = CFDictionaryGetValue(class_isMetaClass(cls) ? metaCache : classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info _update];
    }
    OSSpinLockUnlock(&lock);
    if (!info) {
        info = [[YYClassInfo alloc] initWithClass:cls];
        if (info) {
            OSSpinLockLock(&lock);
            CFDictionarySetValue(info.isMeta ? metaCache : classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            OSSpinLockUnlock(&lock);
        }
    }
    return info;
}

+ (instancetype)classInfoWithClassName:(NSString *)className {
    Class cls = NSClassFromString(className);
    return [self classInfoWithClass:cls];
}

@end
