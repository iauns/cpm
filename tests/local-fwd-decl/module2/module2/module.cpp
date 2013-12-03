#include "module.hpp"
#include <sstream>
#include <central/module.hpp>

namespace CPM_MYMODULE2_NS {

std::string module2Function(int num, int num2)
{
  std::stringstream ss;
  ss << "Module 2: (" << num << "," << num2 << ")";
  return ss.str();
}

std::string module2CentralCall(CPM_CENTRAL_NS::CentralExportedClass& c)
{
  c.num1 += 12;
  c.num2 += 6;
  return c.render();
}

} // namespace CPM_MYMODULE2_NS
