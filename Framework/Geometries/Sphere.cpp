#include "Sphere.hpp"

using namespace newbieGE;

void Sphere::GetAabb(const Matrix4X4f& trans, Vector3f& aabbMin, Vector3f& aabbMax) const
{
    Vector3f center;
    GetOrigin(center, trans);
    Vector3f extent({m_fMargin, m_fMargin, m_fMargin});
    aabbMin = center - extent;
    aabbMax = center + extent;
}