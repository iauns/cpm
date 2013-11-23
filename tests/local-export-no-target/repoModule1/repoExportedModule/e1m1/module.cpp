#include "module.hpp"
#include <sstream>

namespace CPM_E1M1_NS {

std::string e1m1Function(const E1M1ExportedStruct& myStruct)
{
  std::stringstream ss;
  ss << "e1m1: (" << myStruct.num1 << "," << myStruct.num2 << ")";
  return ss.str();
}

}
