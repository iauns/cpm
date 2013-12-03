#include "module.hpp"
#include <sstream>
#include <sub/module.hpp>

namespace CPM_CENTRAL_NS {

std::string centralExpFunction(const CentralExportedClass& myStruct)
{
  CentralExportedClass ret;
  ret.num1 = myStruct.num1 + 10;
  ret.num2 = myStruct.num2;
  ret.str = CPM_CENTRAL_SUB_NS::subbedFunction(myStruct.str);
  
  std::stringstream ss;
  ss << "Central Function [" << ret.render() << "]";
  return ss.str();
}

std::string CentralExportedClass::render()
{
  std::stringstream ss;
  ss << "central render (" << num1 << "," << num2 << ") - " << str;
  return ss.str();
}

std::string centralFunction(CentralExportedClass& myStruct)
{
  myStruct.str += "= centralFunction was here =";

  std::stringstream ss;
  ss << "Main central exp says: " << centralExpFunction(myStruct);
  return ss.str();
}

std::string centralFunction2(int num)
{
  std::stringstream ss;
  ss << "Central number: "<< num;
  return CPM_CENTRAL_SUB_NS::subbedFunction(ss.str());
}


}
