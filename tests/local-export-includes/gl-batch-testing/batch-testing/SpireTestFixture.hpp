/// \author James Hughes
/// \date   November 2013

#ifndef SPIRETESTFIXTURE_HPP
#define SPIRETESTFIXTURE_HPP

#include <spire/Interface.hpp>

namespace CPM_BATCH_TESTING_NS {

class SpireTestFixture
{
public:
  SpireTestFixture(const glm::vec4& myTestVec4);
  virtual ~SpireTestFixture();

  void print();
  
private:
  glm::vec4 mVector;
  CPM_SPIRE_NS::Interface* mInterface;
};

} // namespace 

#endif 
