//
//  Notes.m
//  Bento
//
//  Created by Joseph Lau on 6/30/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

/*

 To do:
 
 1) all day menu
 2) fix lag when become active
 3) make sure nothing is broken
 4)// service area?
 // checking service area?
 // map?
 

 
                                      -Old Menu Logic-
 
--------------------------------------------------------------------------------------------
                LEFT MENU                       |             RIGHT MENU
--------------------------------------------------------------------------------------------
 

                                          OPEN/SOLDOUT
--------------------------------------------------------------------------------------------
// 0:00 - 16:29 (12:00am - 4:29pm)
if (now >= 0 && now < 16.5)
 
               get todayLunch.                  |        try to get todayDinner...
                                                |        else try to get nextLunch...
                                                |        else try to get nextDinner.
 
--------------------------------------------------------------------------------------------
// 16:30 - 23:59 (4:30pm - 11:59pm)
if (now >= 16.5 && now < 24)
 
               get todayDinner.                 |        try to get nextLunch...
                                                |        else try to get nextDinner.
 
--------------------------------------------------------------------------------------------


                                              CLOSED
--------------------------------------------------------------------------------------------
// 00:00 - 12.29 (12:00am - 12:29pm)
if (now >= 0 && now < (lunchTime + bufferTime))
 
               try to get todayLunch...         |        try to get todayDinner...
               else try to get todayDinner...   |        else try to get nextLunch...
               else try to get nextLunch...     |        else try to get nextDinner...
               else try to get nextDinner.      |        else don't show a right menu
 
--------------------------------------------------------------------------------------------
// 12:30 - 17:29 (12:30pm - 5:29pm)
else if (now >= (lunchTime + bufferTime) && now < (dinnerTime+bufferTime))
 
               try to get todayDinner...        |        try to get nextLunch...
               else try to get nextLunch...     |        else try to get nextDinner...
               else try to get nextDinner.      |        else don't show a right menu
 
--------------------------------------------------------------------------------------------
// 17.30 - 23:59 (5:30pm - 23:59pm)
else if (now >= (dinnerTime+bufferTime) && now < 24)
 
               try to get nextLunch...          |        try to get nextDinner...
               else try to get nextDinner.      |        else don't show a right menu
 
--------------------------------------------------------------------------------------------
 
 

                                            -New Menu Logic-

--------------------------------------------------------------------------------------------
                  LEFT MENU                         |             RIGHT MENU
--------------------------------------------------------------------------------------------
                 
                 
OPEN/SOLDOUT
 
--------------------------------------------------------------------------------------------

                 
                 
CLOSED
 
--------------------------------------------------------------------------------------------
 
 
 
 
 
 
 
 
 */



