#include "module.hpp"
#include <sstream>

namespace CPM_MODULE2_NS {

std::string module2Function(int num, int num2)
{
  std::stringstream ss;
  ss << "Module 2: (" << num << "," << num2 << ")";
  return ss.str();
}

} // namespace CPM_MODULE2_NS
