//
//  YYClassInfo.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, YYEncodingType) {
    //////////////////////////////////////////////////////////////////////
    ////type encodings解析失败，类型编码未知
    //////////////////////////////////////////////////////////////////////
    YYEncodingTypeUnknown    = 0, ///< unknown
    
    //////////////////////////////////////////////////////////////////////
    ////变量的类型，0 --> 8位 的十六进制
    //////////////////////////////////////////////////////////////////////
    YYEncodingTypeMask       = 0xFF, ///< mask of type value //低8位的Mask掩码，用于得到枚举值的低8位值
    YYEncodingTypeVoid       = 1, ///< void
    YYEncodingTypeBool       = 2, ///< bool
    YYEncodingTypeInt8       = 3, ///< char / BOOL
    YYEncodingTypeUInt8      = 4, ///< unsigned char
    YYEncodingTypeInt16      = 5, ///< short
    YYEncodingTypeUInt16     = 6, ///< unsigned short
    YYEncodingTypeInt32      = 7, ///< int
    YYEncodingTypeUInt32     = 8, ///< unsigned int
    YYEncodingTypeInt64      = 9, ///< long long
    YYEncodingTypeUInt64     = 10, ///< unsigned long long
    YYEncodingTypeFloat      = 11, ///< float
    YYEncodingTypeDouble     = 12, ///< double
    YYEncodingTypeLongDouble = 13, ///< long double
    YYEncodingTypeObject     = 14, ///< id // NSObject （1.Foundation Class 2.自定义NSObject子类）
    YYEncodingTypeClass      = 15, ///< Class
    YYEncodingTypeSEL        = 16, ///< SEL
    YYEncodingTypeBlock      = 17, ///< block
    YYEncodingTypePointer    = 18, ///< void*
    YYEncodingTypeStruct     = 19, ///< struct
    YYEncodingTypeUnion      = 20, ///< union
    YYEncodingTypeCString    = 21, ///< char* C字符串
    YYEncodingTypeCArray     = 22, ///< char[10] (for example) C 数组
    
    //////////////////////////////////////////////////////////////////////
    ////method encodings，8 --> 16位 的十六进制
    //////////////////////////////////////////////////////////////////////
    YYEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier //低16位的Mask掩码，用于得到枚举值的低16位值
    YYEncodingTypeQualifierConst  = 1 << 8,  ///< const
    YYEncodingTypeQualifierIn     = 1 << 9,  ///< in
    YYEncodingTypeQualifierInout  = 1 << 10, ///< inout
    YYEncodingTypeQualifierOut    = 1 << 11, ///< out
    YYEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    YYEncodingTypeQualifierByref  = 1 << 13, ///< byref
    YYEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    //////////////////////////////////////////////////////////////////////
    ////属性修饰类型，16 --> 24位 的十六进制
    //////////////////////////////////////////////////////////////////////
    YYEncodingTypePropertyMask         = 0xFF0000, ///< mask of property //低24位的Mask掩码，用于得到枚举值的低24位值
    YYEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    YYEncodingTypePropertyCopy         = 1 << 17, ///< copy
    YYEncodingTypePropertyRetain       = 1 << 18, ///< retain
    YYEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    YYEncodingTypePropertyWeak         = 1 << 20, ///< weak
    YYEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    YYEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    YYEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

/**
 Get the type from a Type-Encoding string.
 
 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
YYEncodingType YYEncodingGetType(const char *typeEncoding);


/**
 Instance variable information.
 
 YYClassIvarInfo 对每一个Ivar变量的抽象类
 
 */
@interface YYClassIvarInfo : NSObject
/** 变量 -write by khzliu */
@property (nonatomic, assign, readonly) Ivar ivar;

/** 变量的名称 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *name; ///< Ivar's name

/** 变量的偏移量 用来保存两个‘指针’减法操作的结果 -write by khzliu */
@property (nonatomic, assign, readonly) ptrdiff_t offset; ///< Ivar's offset

/** Ivar的系统编码 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< Ivar's type encoding

/** Ivar编码格式对应的枚举 -write by khzliu */
@property (nonatomic, assign, readonly) YYEncodingType type; ///< Ivar's type

/** 初始化当前Ivar在 Class中所有Ivar的 信息 -write by khzliu */
- (instancetype)initWithIvar:(Ivar)ivar;
@end

/**
 Method information.
 YYClassMethodInfo，对Class的每一个Method的抽象
 */
@interface YYClassMethodInfo : NSObject
/** objc_method结构体实例 -write by khzliu */
@property (nonatomic, assign, readonly) Method method;

/** object_method实例的名字字符串 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *name; ///< method name

/** object_method的SEL值 -write by khzliu */
@property (nonatomic, assign, readonly) SEL sel; ///< method's selector

/** object_method实例的IMP实现指针 -write by khzliu */
@property (nonatomic, assign, readonly) IMP imp; ///< method's implementation

/** 方法的编码 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< method's parameter and return types

/** 方法返回值的编码 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding; ///< return value's type

/** 方法所有返回值的编码 -write by khzliu */
@property (nonatomic, strong, readonly) NSArray *argumentTypeEncodings; ///< array of arguments' type

/** 对象实例化方法 -write by khzliu */
- (instancetype)initWithMethod:(Method)method;
@end

/**
 Property information.
 
 YYClassPropertyInfo，对Class的每一个Property的抽象
 
 主要是对属性的特征值（系统编码）的操作，来解析得到属性变量的数据类型（参照Type Encodings）
 
 objc_property_attribute_t 属性特征值（编码）结构体
 
 属性的编码都是以T字符开始，获取属性声明的Ivar的 数据类型，如: T@User获取自定义类型User
 V字符，获取属性声明的Ivar的 变量名
 以及其他字符，获取对应的数据
 N
 C
 &
 R
 G
 S
 等等…
 总之YYClassPropertyInfo类，对objc_property_t的抽象封装
 
 解析属性变量的数据类型
 得到属性的 type encodings attribute 字符串
 eg、T@"User",&,N,V_user
 然后解析最前面T开头的一段字符串
 T@User >>> 属性变量类型是 User
 Ti >>> 属性变量类型是 int
 TB >>> 属性变量类型是 bool、BOOL
 TD >>> 属性变量类型是 Double
 Tf >>> 属性变量类型是 float
 等等…

 */
@interface YYClassPropertyInfo : NSObject
/** 属性 -write by khzliu */
@property (nonatomic, assign, readonly) objc_property_t property;

/** 属性的名称 -write by khzliu */
@property (nonatomic, strong, readonly) NSString *name; ///< property's name

/**
 *  属性`变量`类型的编码，对应的枚举值
 *
 *  PropertyMeta对象也是根据PropertyModel对象的这个
 *  属性枚举值来知道属性变量的数据类型
 */
@property (nonatomic, assign, readonly) YYEncodingType type; ///< property's type

/**
 *  属性`变量`类型的编码，如:
 @User、
 @NSString、
 @NSArray、
 {example=^id*iB^{example}}结构体变量的编码
 */
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< property's encoding value

/**
 *  属性`变量`名字
 */
@property (nonatomic, strong, readonly) NSString *ivarName; ///< property's ivar name

/**
 *  属性变量Ivar的Class类型
 */
@property (nonatomic, assign, readonly) Class cls; ///< may be nil

/**
 *  属性的getter方法
 */
@property (nonatomic, strong, readonly) NSString *getter; ///< getter (nonnull)

/**
 *  属性的setter方法
 */
@property (nonatomic, strong, readonly) NSString *setter; ///< setter (nonnull)

/**
 *  传入一个属性创建属性模型
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end

/**
 Class information for a class.
 */
@interface YYClassInfo : NSObject

@property (nonatomic, assign, readonly) Class cls;
@property (nonatomic, assign, readonly) Class superCls;
@property (nonatomic, assign, readonly) Class metaCls;
@property (nonatomic, assign, readonly) BOOL isMeta;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) YYClassInfo *superClassInfo;

@property (nonatomic, strong, readonly) NSDictionary *ivarInfos;     ///< key:NSString(ivar),     value:YYClassIvarInfo
@property (nonatomic, strong, readonly) NSDictionary *methodInfos;   ///< key:NSString(selector), value:YYClassMethodInfo
@property (nonatomic, strong, readonly) NSDictionary *propertyInfos; ///< key:NSString(property), value:YYClassPropertyInfo

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 
 After called this method, you may call 'classInfoWithClass' or 
 'classInfoWithClassName' to get the updated class info.
 */
- (void)setNeedUpdate;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param cls A class.
 @return A class info, or nil if an error occurs.
 */
+ (instancetype)classInfoWithClass:(Class)cls;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param className A class name.
 @return A class info, or nil if an error occurs.
 */
+ (instancetype)classInfoWithClassName:(NSString *)className;

@end
