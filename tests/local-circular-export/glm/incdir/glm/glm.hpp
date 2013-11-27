/// \author James Hughes
/// \date   November 2013

#ifndef GLM_HPP
#define GLM_HPP

namespace glm {

class vec4
{
public:
  vec4()            {x=y=z=w=0;}
  virtual ~vec4()   {}
  
  float x,y,z,w;
};

} // namespace glm 

#endif 
