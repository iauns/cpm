#include "module.hpp"
#include <sstream>
#include "central/module.hpp"

namespace CPM_MODULE3_NS {

std::string module3Function(const std::string& in, int num)
{
  std::stringstream ss;
  ss << "Module 3 (yay!): (" << in << ")" << " num - " <<
     << CPM_CENTRALIZED_NS::centralFunction2(num);
  return ss.str();
}

} // namespace CPM_MODULE3_NS
