#include "module.hpp"
#include <sstream>

namespace CPM_SUBBED_NS {

std::string subbedFunction(const std::string& str)
{
  std::stringstream ss;
  ss << "e1m1: (" << myStruct.num1 << "," << myStruct.num2 << ")";
  return ss.str();
}

}
