#include "module.hpp"
#include <sstream>

namespace CPM_SUBBED_NS {

std::string subbedFunction(const std::string& str)
{
  std::stringstream ss;
  ss << "subbed string: (" << str << ")";
  return ss.str();
}

}
