#include "module.hpp"
#include <sstream>
#include "central_sub/module.hpp"
#include "central_exp/module.hpp"

namespace CPM_CENTRAL_NS {

std::string centralFunction(CPM_CENTRAL_EXP_NS::CentralSubExportedStruct& myStruct)
{
  myStruct.str += "= centralFunction was here =";

  std::stringstream ss;
  ss << "Main central exp says: " << CPM_CENTRAL_EXP_NS::centralExpFunction(myStruct);
  return ss.str();
}

std::string centralFunction2(int num)
{
  std::stringstream ss;
  ss << "Central number: "<< num;
  return CPM_CENTRAL_SUB_NS::subbedFunction(ss.str());
}


}
