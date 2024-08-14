#pragma language glsl3

uniform number time;
uniform number amp;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 pixel_coords)
{
  vec4 pixel = Texel(tex, texture_coords);
  return pixel * amp * vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
}
