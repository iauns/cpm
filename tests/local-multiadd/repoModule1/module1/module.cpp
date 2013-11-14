#include "module.hpp"
#include <sstream>

namespace CPM_MODULE1_NS {

std::string module1Function(const CPM_E1M1_GOOFY_NS::E1M1ExportedStruct& myStruct)
{
  std::stringstream ss;
  ss << "Module 1 says: " << CPM_E1M1_GOOFY_NS::e1m1Function(myStruct);
  return ss.str();
}

}
