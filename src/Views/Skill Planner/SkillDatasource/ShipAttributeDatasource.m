//
//  ShipAttributeDatasource.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 9/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShipAttributeDatasource.h"

#import "CCPType.h"
#import "Character.h"
#import "CCPTypeAttribute.h"
#import "CCPDatabase.h"


@implementation ShipAttributeDatasource

-(void) addAttribute:(NSArray*)attrType groupName:(NSString*)groupName
{
	if(attrType != nil){
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Name",attrType,@"Data",nil];
		[attributes addObject:dict];
	}
}

-(void) loadAttributes
{
	attributes = [[NSMutableArray alloc]initWithCapacity:8];
	NSInteger typeID = [ship typeID];
	NSArray *attrType;
	//NSDictionary *dict;
	
	attrType = [db attributeForType:typeID groupBy:Fitting];
	[self addAttribute:attrType groupName:@"Fitting"];
	
	attrType = [db attributeForType:typeID groupBy:Drones];
	[self addAttribute:attrType groupName:@"Drones"];
	
	attrType = [db attributeForType:typeID groupBy:Structure];
	[self addAttribute:attrType groupName:@"Structure"];
	
	attrType = [db attributeForType:typeID groupBy:Armour];
	[self addAttribute:attrType groupName:@"Armour"];
	
	attrType = [db attributeForType:typeID groupBy:Shield];
	[self addAttribute:attrType groupName:@"Shield"];
	
	attrType = [db attributeForType:typeID groupBy:Cap];
	[self addAttribute:attrType groupName:@"Capacitor"];
	
	attrType = [db attributeForType:typeID groupBy:Targeting];
	[self addAttribute:attrType groupName:@"Targeting"];
	
	attrType = [db attributeForType:typeID groupBy:Other];
    if( [ship capacity] > 0 )
    {
        // A hack to at least have the ship's cargo capacity show
        NSMutableArray *mutAttrType = (NSMutableArray *)attrType;
        CCPTypeAttribute *ta = [CCPTypeAttribute createTypeAttribute:0
															dispName:@"Capacity"
														 unitDisplay:@"m3"
															valueInt:NSIntegerMax
														  valueFloat:[ship capacity]];
        [mutAttrType addObject:ta];
    }
	[self addAttribute:attrType groupName:@"Other"];
}

-(void)dealloc
{
	[ship release];
	[character release];
	[attributes release];
	[super dealloc];
}

-(ShipAttributeDatasource*) initWithShip:(CCPType*)type forCharacter:(Character*)ch
{
	if(self = [super init]){
		ship = [type retain];
		character = [ch retain];
		db = [ship database]; //not retained. do not release.
		
		[self loadAttributes];
	}
	
	return self;
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView 
 numberOfChildrenOfItem:(id)item
{
	if(item == nil){
		return [attributes count];
	}
	
	return [[item valueForKey:@"Data"]count];
}

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	if(item == nil){
		return [attributes objectAtIndex:index];
	}
	//return [item objectAtIndex:index];
	
	NSArray *ary = [item valueForKey:@"Data"];
	return [ary objectAtIndex:index];
}

// Special preprocessing for values from the database
// (which sometimes have some weird format)
- (NSMutableString*)renderValue: (id)item
{
	NSMutableString *str = [[[NSMutableString alloc]init]autorelease];
	NSString *unit = [item unitDisplay];
	NSString *dn = [item displayName];
    
	if ([dn isEqualToString:@"Rig Size"]) {
		// show rig size as a word, not as a number
		double raw_val = [item valueFloat];
		NSString *val;
		if (raw_val == 1.0){
			val = @"small";
		}
		else if (raw_val == 2.0){
			val = @"medium";
		}
		else if (raw_val == 3.0){
			val = @"large";
		}
		else if (raw_val == 4.0){
			val = @"capital";
		}
		else{
			val = [NSString stringWithFormat:@"%.2f",raw_val];
		}
		[str appendString:val];
	}
	else if ([dn isEqualToString:@"Maximum Targeting Range"]) {
		// show targeting range in kilometers
		[str appendFormat:@"%.2f km",(double)[item valueFloat] / 1000];
	}
	else if ([dn hasSuffix:@"esistance"]) {
		// show shield resistance the way it's shown in game
		double raw_val = (1.0 - [item valueFloat]) * 100;
		double eps = 1e-6;
		if (fabs(round(raw_val) - raw_val) < eps) {
			[str appendFormat:@"%d%%",(int)round(raw_val)];
		}
		else if (fabs(round(raw_val * 10) - raw_val * 10) < eps) {
			[str appendFormat:@"%.1f%%",raw_val];
		}
		else {
			[str appendFormat:@"%.2f%%",raw_val];
		}
	}
	else if ([dn hasSuffix:@"echarge time"]) {
		// show recharge time properly (for some reason the database has value in ms with unit="s")
		double raw_val = [item valueFloat] / 1000;
		double eps = 1e-6;
		if (fabs(round(raw_val) - raw_val) < eps) {
			[str appendFormat:@"%d",(int)round(raw_val)];
		}
		else if (fabs(round(raw_val * 10) - raw_val * 10) < eps) {
			[str appendFormat:@"%.1f",raw_val];
		}
		else {
			[str appendFormat:@"%.2f",raw_val];
		}
		[str appendFormat:@" %@",unit];
	}
	else {
		// just render the value depending on its type
        if( [@"typeID" isEqualToString:unit] )
        {
            // lookup value as a typeID and get the name of the type
            NSInteger typeInt = [item valueInt];
            if( NSIntegerMax == typeInt )
                typeInt = [item valueFloat];
            CCPType *type = [db type:typeInt];
            if( type && ([[type typeName] length] > 0) )
            {
                [str appendString:[type typeName]];
                return str;
            }
        }
        else if( [@"1=True 0=False" isEqualToString:unit] )
        {
            NSInteger typeInt = [item valueInt];
            if( NSIntegerMax == typeInt )
                typeInt = [item valueFloat];
            [str appendString:typeInt?@"True":@"False"];
            return str;
        }
        
		if([item valueInt] != NSIntegerMax){
			[str appendFormat:@"%ld", (long)[item valueInt]];
		}
        else
        {
            BOOL displayAsInt = NO;
            
            if( [@"hardpoints" isEqualToString:unit]
               || [@"points" isEqualToString:unit]
               || [@"HP" isEqualToString:unit]
               || [@"Level" isEqualToString:unit]
               || [dn hasSuffix:@" Slots"]
               || [dn isEqualToString:@"Maximum Locked Targets"] )
                displayAsInt = YES;
            
            if( displayAsInt )
                [str appendFormat:@"%.0f",(double)[item valueFloat]];
            else
                [str appendFormat:@"%.2f",(double)[item valueFloat]];
		}
        
		if( (unit != nil) && ![unit isEqualToString:@"Level"] )
        {
			[str appendFormat:@" %@",unit];
		}
	}
    
	return str;
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if([item isKindOfClass:[CCPTypeAttribute class]]){
		if([[tableColumn identifier]isEqualToString:@"ATTR_NAME"]){
			return [item displayName];
		}
		if([[tableColumn identifier]isEqualToString:@"ATTR_VALUE"]){
            return [self renderValue: item];
		}
	}
	
	if([item isKindOfClass:[NSDictionary class]]){
		if([[tableColumn identifier]isEqualToString:@"ATTR_NAME"]){
			NSString *str = [item valueForKey:@"Name"];
			return str;
		}
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	if([item isKindOfClass:[CCPTypeAttribute class]]){
		return NO;
	}
	return YES;
}


@end
