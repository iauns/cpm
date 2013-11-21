#include "module.hpp"
#include <sstream>
#include "central/module.hpp"

namespace CPM_MODULE3_NS {

std::string module3Function(const std::string& in, int num,
                            CPM_CENTRAL_EXP_NS::CentralExportedClass& c)
{
  std::stringstream ss;
  ss << "Module 3 (yay!): (" << in << ")" << " num - "
     << CPM_CENTRALIZE_NS::centralFunction2(num);
  return ss.str() + c.render();
}

} // namespace CPM_MODULE3_NS
