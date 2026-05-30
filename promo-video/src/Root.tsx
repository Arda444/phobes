import React from 'react';
import { Composition } from 'remotion';
import { PhobesPromo, SCENES, TOTAL_DURATION } from './PhobesPromo';

const FPS = 30;
const WIDTH = 1080;
const HEIGHT = 1920;

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* Ana dikey video */}
      <Composition
        id="PhobesPromo"
        component={PhobesPromo}
        durationInFrames={TOTAL_DURATION}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />

      {/* Tek tek sahneleri önizlemek/render etmek için ayrı kompozisyonlar */}
      {SCENES.map((s) => (
        <Composition
          key={s.id}
          id={`scene-${s.id}`}
          component={s.Component as React.FC}
          durationInFrames={s.duration}
          fps={FPS}
          width={WIDTH}
          height={HEIGHT}
        />
      ))}
    </>
  );
};
