#include <iostream>
#include <batch-testing/SpireTestFixture.hpp>

int main(int argc, char* av[])
{
  glm::vec4 myVec4;
  myVec4.x = 1.0f;
  myVec4.y = 2.3f;
  myVec4.z = 3.0f;
  myVec4.w = 4.9f;

  CPM_GL_BATCH_TESTING_NS::SpireTestFixture* fixture = new CPM_GL_BATCH_TESTING_NS::SpireTestFixture(myVec4);
  fixture->print();

  delete fixture;
  return 0;
}
