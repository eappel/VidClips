//
//  VCMovieWriterProgressObject.h
//  Pods
//
//  Created by Eric Appel on 3/20/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    GPUImageMovieWriterStatusInitial,
    GPUImageMovieWriterStatusWriting,
    GPUImageMovieWriterStatusFinished
}GPUImageMovieWriterStatus;

@interface VCMovieWriterProgressObject : NSObject

@property (nonatomic, assign) int Exposure;
@property (nonatomic, assign) int Pink;
@property (nonatomic, assign) int Green;
@property (nonatomic, assign) int Yellow;
@property (nonatomic, assign) int Blue;
@property (nonatomic, assign) int Sepia;
@property (nonatomic, assign) int Amatorka;
@property (nonatomic, assign) int Etikate;
@property (nonatomic, assign) int SoftElegance;
@property (nonatomic, assign) int Pixellate;
@property (nonatomic, assign) int PolarPixellate;
@property (nonatomic, assign) int Dots;
@property (nonatomic, assign) int Halftone;
@property (nonatomic, assign) int Toon;
@property (nonatomic, assign) int Emboss;
@property (nonatomic, assign) int Vignette;

@end
