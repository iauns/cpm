#include "module.hpp"
#include <sstream>

#include "sub/module.hpp"

namespace CPM_CENTRAL_EXP_NS {

std::string CentralExportedClass::render()
{
  std::stringstream ss;
  ss << "central render (" << num1 << "," << num2 << ") - " << str;
  return ss.str();
}

std::string centralExpFunction(const CentralExportedClass& myStruct)
{
  CentralExportedClass ret;
  ret.num1 = myStruct.num1 + 10;
  ret.num2 = myStruct.num2;
  ret.str = CPM_CENTRAL_SUBBED_NS::subbedFunction(myStruct.str) + DEF_INC1 + DEF_INC2;
  
  std::stringstream ss;
  ss << "Central Function [" << ret.render() << "]";
  return ss.str();
}

}
