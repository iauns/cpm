#include "module.hpp"
#include "cpm-test-01/module.hpp"
#include <sstream>

namespace CPM_MODULE1_NS {

std::string module1Function(int num)
{
  std::stringstream ss;
  ss << "Module 1: (" << num << ") - "
     << CPM_TEST_01_NS::test01Function("Direct call:");
  return ss.str();
}

}
