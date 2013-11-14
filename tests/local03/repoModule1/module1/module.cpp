#include "module.hpp"
#include <sstream>

namespace CPM_MODULE1_NS {

std::string module1Function(int num)
{
  std::stringstream ss;
  ss << "Module 1: (" << num << ")";
  return ss.str();
}

}
