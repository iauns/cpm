#include "module.hpp"
#include "cpm-test-01/module.hpp"
#include <sstream>

namespace CPM_MODULE2_NS {

std::string module2Function(int num, int num2)
{
  std::stringstream ss;
  ss << "Module 2: (" << num << "," << num2 << ") - "
     << CPM_TEST_01_NS::test01Function("Direct call:", 12);
  return ss.str();
}

} // namespace CPM_MODULE2_NS
